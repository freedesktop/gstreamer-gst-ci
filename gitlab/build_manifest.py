#!/usr/bin/env python3

import os
import requests
import sys

from typing import Dict, Tuple, List

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
  <remote fetch="%s" name="user"/>
  <remote fetch="https://gitlab.freedesktop.org/gstreamer/" name="gstreamer"/>
  <remote fetch="git://anongit.freedesktop.org/gstreamer/" name="origin"/>
%s
</manifest>"""


def request(path: str) -> Dict[str, str]:
    gitlab_header: Dict[str, str] = {'JOB_TOKEN': os.environ["CI_JOB_TOKEN"]}

    return requests.get('https://gitlab.gnome.org/api/v4/' + path, headers=gitlab_header).json()


def find_repository_sha(module: str, branchname: str) -> Tuple[str, str]:
    for project in request('projects?search=' + module):
        if project['name'] != module:
            continue

        if 'namespace' not in project:
            # print("No 'namespace' in: %s - ignoring?" % project, file=sys.stderr)
            continue

        if project['namespace']['name'] in useful_namespaces:
            if project['namespace']['name'] == user_namespace:
                # If we have a branch with same name, use it.
                for branch in request('%s/repository/branches' % project['id']):
                    if branch['name'] == branchname:
                        print("%s/%s" % (project['namespace']['name'], branchname))

                        return 'user', branch['commit']['id']
            else:
                for branch in request('%s/repository/branches"' % project['id']):
                    if branch['name'] == branchname:
                        print("gstreamer/%s" % (branchname))
                        return 'gstreamer', branch['commit']['id']

                branch, = request('%s/repository/branches?search=master' % project['id'])
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
    project_template: str = '  <project name="%s" remote="%s" revision="%s" />\n'
    user_remote: str = os.path.dirname(os.environ['CI_PROJECT_URL'])
    for module in GSTREAMER_MODULES:
        print("Checking %s:" % module, end=' ')

        remote = "origin"
        revision = None
        if module == project_name:
            revision = os.environ['CI_COMMIT_SHA']
            remote = "user"
            print("%s/%s" % (user_namespace, branchname))
        else:
            remote, revision = find_repository_sha(module, branchname)

        if not revision:
            revision = 'master'
        projects += project_template % (module, remote, revision)

    with open('manifest.xml', mode='w') as manifest:
        print(MANIFEST_TEMPLATE % (user_remote, projects), file=manifest)
