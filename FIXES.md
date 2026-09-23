# Fixes

List every problem you found in the starter files. For each one, note
the file, the fix, and why it matters for a service running across
3,000 outlets.

## Problem 1

File: Dockerfile
Fix: Old Dockerfile built and ran the app from the same `maven:latest` image, so the final container had the whole JDK and Maven in it, not just the app. It also ran as root and had no EXPOSE. Now it builds in one stage (Maven + JDK) then copies just the finished jar into a small second image that only has a Java runtime, running as a non-root user, with pinned versions instead of `latest`.
Why it matters: Extra tools in the running container just give an attacker more to work with if they get in, and root access makes that worse. Pinning versions means the build doesn't quietly change under you.

## Problem 2

File:
Fix:
Why it matters:
