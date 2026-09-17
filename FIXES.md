# Fixes

List every problem you found in the starter files. For each one, note
the file, the fix, and why it matters for a service running across
3,000 outlets.

## Problem 1

File: Dockerfile
Fix: Old Dockerfile built and ran the app from the same `maven:latest` image, so the final container had the whole JDK and Maven in it, not just the app. It also ran as root and had no EXPOSE. Now it builds in one stage (Maven + JDK) then copies just the finished jar into a small second image that only has a Java runtime, running as a non-root user, with pinned versions instead of `latest`.
Why it matters: Extra tools in the running container just give an attacker more to work with if they get in, and root access makes that worse. Pinning versions means the build doesn't quietly change under you.

## Problem 2

File: pom.xml
Fix: Removed the log4j-core 2.14.1 dependency - it's not used anywhere in the code (Spring Boot logs through Logback by default) and it's the Log4Shell CVE version. Also added a JaCoCo rule that fails the build if line coverage drops below 70%, wired into the `verify` phase so it runs the same way locally and in CI.
Why it matters: An unused dependency with a known critical CVE is still a risk if anyone ever triggers it, and it was serving no purpose. The coverage gate stops the build from silently accepting untested code as it grows.

## Problem 3

File:
Fix:
Why it matters:
