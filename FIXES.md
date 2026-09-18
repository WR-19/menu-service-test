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

File: infra/main.tf
Fix: Set `https_only = true` on the Web App. Removed `admin_enabled = true` on the ACR (shared static credentials) and instead gave the Web App a system-assigned managed identity with the `AcrPull` role, so it pulls images without a password. Added a Key Vault holding the DB password as a secret, with the Web App's identity granted access to read it. Added a Log Analytics workspace and Application Insights, wired into the Web App's app settings.
Why it matters: Plain HTTP means traffic can be read in transit. A shared ACR password never expires and works for anyone who has it; a managed identity is scoped to just that one app and can be revoked on its own. No Key Vault meant the DB password had nowhere safe to be stored. No App Insights/Log Analytics meant no visibility if something broke in production.

## Problem 4

File: azure-pipelines.yml
Fix: Trigger was any branch, now master only. Hardcoded password removed, pulled from Key Vault instead. Removed continueOnError on tests. Split into 4 stages (Build&Test, Scan, Deploy Dev, Deploy Prod) with a Trivy scan before push, build-ID tags instead of latest, manual approval + 06:00-10:00 blackout on prod, smoke test after each deploy.
Why it matters: Same reasoning as the other bugs - broken code could ship silently, a hardcoded password is a leaked credential, latest tags make rollback guesswork. Manual approval + blackout window matter because this deploys in front of real tills during breakfast rush (6-10am).

## Problem 5

File: pom.xml
Fix: Upgraded Spring Boot 2.7.18 (EOL) to 3.5.3, no code changes needed. Trivy scan before/after: 43 vulnerabilities (8 CRITICAL) down to 25 (6 CRITICAL).
Why it matters: An EOL version never gets patched again - every CVE against it is permanent. What's left is new CVEs against a version that's still actively maintained, so those will actually get fixed.
