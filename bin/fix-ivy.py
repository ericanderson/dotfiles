#!/usr/bin/python

# alanp's fix-ivy script, version 1

import urllib2
import re
import datetime
import bisect
import commands

ivyPropertiesFilename = 'plans/ivysettings-shared.xml'
versionKey = '  <property name="version.product" value="'

def getCurrentBranch():
    try:
        ivyPropertiesFile = open(ivyPropertiesFilename, 'r')
    except Exception:
        print("Error opening file " + ivyPropertiesFilename)
        print("Are you running this from the root git checkout directory (usually pgdev)?")
        exit(1)

    for line in ivyPropertiesFile:
        if line.startswith(versionKey):
            fullVersion = line[len(versionKey):]
            thirdDotIndex = fullVersion.replace('.', '_', 2).find('.')
            ivyPropertiesFile.close()
            return fullVersion[0:thirdDotIndex]
    ivyPropertiesFile.close()
    print("Unable to find the current branch from the file " + ivyPropertiesFilename)
    exit(1)


# Returns a list of lists of the form [date, expanded version, version string]
def getBranchIvyVersions(branch):
    htmlContents = urllib2.urlopen('http://ivy/modules/palantir/pttileserver/').read()
    htmlLines = htmlContents.split("\n")
    goodLines = filter(lambda s: s.find('a href="' + branch) != -1, htmlLines)

    htmlTagPattern = re.compile(r'<.*?>')
    def parseHtml(line):
        splitLine = htmlTagPattern.split(line)
        tokens = filter(lambda s: len(s) > 0, splitLine)

        version = tokens[0].strip().rstrip('/')
        dateString = tokens[1].strip()
        date = datetime.datetime.strptime(dateString, '%d-%b-%Y %H:%M')

        return [date, version.split("."), version]

    return sorted(map(parseHtml, goodLines))


# Finds the commit date for the most recent gerrit merge commit
def getCurrentDate():
    dateLineRaw = commands.getoutput('git log --committer="Gerrit Code Review" -n 1 --format="%ct"')
    return datetime.datetime.fromtimestamp(int(dateLineRaw))


def setIvyVersion(versionString):
    newVersionLine = versionKey + versionString + '" />\n'

    ivyPropertiesFile = open(ivyPropertiesFilename, 'r')
    lines = ivyPropertiesFile.readlines()
    for i, line in enumerate(lines):
        if line.startswith(versionKey):
            lines[i] = newVersionLine

    ivyPropertiesFile.close()
    ivyPropertiesFile = open(ivyPropertiesFilename, 'w')
    ivyPropertiesFile.writelines(lines)
    ivyPropertiesFile.close()


branchName = getCurrentBranch()
print('Finding ivy versions with branch ' + branchName + '.')
ivyVersions = getBranchIvyVersions(branchName)
currentDate = getCurrentDate()
print('Git HEAD is based off of commit with date ' + str(currentDate) + '.')
index = bisect.bisect_left(ivyVersions, [currentDate])
if index >= len(ivyVersions):
    index = len(ivyVersions) - 1
newIvyVersion = ivyVersions[index][2]
print('Setting version to ' + newIvyVersion + '.')
setIvyVersion(newIvyVersion)
print('Done.')
