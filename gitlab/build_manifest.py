#!/usr/bin/env python3

import os
import requests
import sys

from typing import Dict, Tuple, List
from urllib.parse import urlparse

GSTREAMER_MODULES: List[str] = [
    # 'orc',
    'gst-build',
    'gstreamer',
    'gst-plugins-base',
    'gst-plugins-good',
    'gst-plugins-bad',
    'gst-plugins-ugly',
    'gst-libav',
    'gst-devtools',
    'gst-docs',
    'gst-editing-services',
    'gst-omx',
    'gst-python',
    'gst-rtsp-server'
]

MANIFEST_TEMPLATE: str = """<?xml version="1.0" encoding="UTF-8"?>
<manifest>
  <remote fetch="{}" name="user"/>
  <remote fetch="https://gitlab.freedesktop.org/gstreamer/" name="gstreamer"/>
  <remote fetch="git://anongit.freedesktop.org/gstreamer/" name="origin"/>
{}
</manifest>"""


def request_raw(path: str, token: str, project_url: str) -> Dict[str, str]:
    gitlab_header: Dict[str, str] = {'JOB_TOKEN': token }
    base_url: str = get_hostname(project_url)

    return requests.get(f"https://{base_url}/api/v4/" + path, headers=gitlab_header).json()


def request(path: str) -> Dict[str, str]:
    token = os.environ["CI_JOB_TOKEN"]
    project_url = os.environ['CI_PROJECT_URL']
    return request_raw(path, token, project_url)


def get_hostname(url: str) -> str:
    return urlparse(url).hostname


def test_get_hostname():
    gitlab = 'https://gitlab.com/example/a_project'
    assert get_hostname(gitlab) == 'gitlab.com'

    fdo = 'https://gitlab.freedesktop.org/example/a_project'
    assert get_hostname(fdo) == 'gitlab.freedesktop.org'


def find_repository_sha(module: str, branchname: str) -> Tuple[str, str]:
    # FIXME: This does global search query in the whole gitlab instance.
    # It has been working so far by a miracle. It should be limited only to
    # the current namespace instead.
    for project in request('projects?search=' + module):
        if project['name'] != module:
            continue

        if 'namespace' not in project:
            # print("No 'namespace' in: %s - ignoring?" % project, file=sys.stderr)
            continue

        id = project['id']
        if project['namespace']['path'] in useful_namespaces:
            if project['namespace']['path'] == user_namespace:
                # If we have a branch with same name, use it.
                for branch in request(f"{id}/repository/branches"):
                    if branch['name'] == branchname:
                        name = project['namespace']['path']
                        print(f"{name}/{branchname}")

                        return 'user', branch['commit']['id']
            else:
                for branch in request(f"{id}/repository/branches"):
                    if branch['name'] == branchname:
                        print(f"gstreamer/{branchname}")
                        return 'gstreamer', branch['commit']['id']

                branch, = request(f"{id}/repository/branches?search=master")
                print('gstreamer/master')
                return 'gstreamer', branch.attributes['commit']['id']

    print('origin/master')
    return 'origin', 'master'

if __name__ == "__main__":
    user_namespace: str = os.environ['CI_PROJECT_NAMESPACE']
    project_name: str = os.environ['CI_PROJECT_NAME']
    branchname: str = os.environ['CI_COMMIT_REF_NAME']

    useful_namespaces: List[str] = ['gstreamer']
    if branchname != 'master':
        useful_namespaces.append(user_namespace)

    # Shouldn't be needed.
    remote: str = "git://anongit.freedesktop.org/gstreamer/"
    projects: str = ''
    project_template: str = "  <project name=\"{}\" remote=\"{}\" revision=\"{}\" />\n"
    user_remote: str = os.path.dirname(os.environ['CI_PROJECT_URL'])
    for module in GSTREAMER_MODULES:
        print(f"Checking {module}:", end=' ')

        remote = 'origin'
        revision = None
        if module == project_name:
            revision = os.environ['CI_COMMIT_SHA']
            remote = 'user'
            print(f"{user_namespace}/{branchname}")
        else:
            remote, revision = find_repository_sha(module, branchname)

        if not revision:
            revision = 'master'
        projects += project_template.format(module, remote, revision)

    with open('manifest.xml', mode='w') as manifest:
        print(MANIFEST_TEMPLATE.format(user_remote, projects), file=manifest)
