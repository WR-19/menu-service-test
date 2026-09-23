# SSP Menu Service, take-home exercise

## Scenario

Point-of-sale systems in SSP outlets call this Menu Service to get the
current menu and prices for a unit. Your job is to build, test, secure
and deploy the service to Azure through Azure DevOps. One rule applies:
SSP blocks production deployments between 06:00 and 10:00 UK time,
because breakfast is the busiest trading period.

## What you have

- A Spring Boot API built with Maven, with two endpoints:
  `GET /menu/{unitId}` and `GET /health`.
- A starter `Dockerfile`, a starter `azure-pipelines.yml`, and a starter
  `infra/main.tf`. These starter files contain problems.

## Time limit

Spend no more than 3 hours. When you reach 3 hours, stop and list your
next steps at the bottom of this file.

## Tasks

1. Review and fix. Find the problems in the starter files. Fix each one
   and record what you changed and why it matters in `FIXES.md`.
2. Containerise. Write a multi-stage `Dockerfile`. Build with Maven in
   the first stage and run on a slim Java runtime image in the second.
   Run the app as a non-root user.
3. Infrastructure as Code. Define an Azure Container Registry, an App
   Service for Linux containers, a Key Vault, and Application Insights
   with a Log Analytics workspace, using Terraform. Use one
   configuration with a dev and a prod tfvars file.
4. Pipeline. Write a multi-stage `azure-pipelines.yml`: build and unit
   test with Maven, publish test results and coverage, fail the build
   below 70% coverage, scan the image for vulnerabilities, push to the
   registry, deploy to dev on every merge to main, and deploy to prod
   after a manual approval. Enforce the 06:00 to 10:00 block for prod.
5. Smoke test. Write a PowerShell script the pipeline runs after each
   deployment. Call `/health` and `/menu/LHR-T5-001`, retry up to 5
   times with 10 seconds between attempts, and exit non-zero on
   failure.
6. Monitoring. Add an alert that fires when prod returns more than 10
   HTTP 5xx responses in 5 minutes.

## What to submit

- A link to this repository with full commit history. Commit as you
  work.
- `FIXES.md`, covering every problem you found.
- This `README.md`, updated with your design choices, three things you
  left out and why, and what you would change to run this service
  across 38 countries.
- Optional: a screenshot of a successful pipeline run.

## Use of AI tools

You can use AI tools while you work. In the follow-up session you will
walk through every file and answer questions without AI help, and make
live changes to your solution while sharing your screen. Submit only
work you understand.


## My work:
## How I used AI

Used Claude Code as a pairing tool, not an autopilot - I drove all the actual changes (GitHub Desktop, Azure Portal, Azure DevOps setup) myself, and treated every fix as unverified until I'd actually run it. A few real examples from debugging along the way:

- Docker image pulled fine locally but failed on the real Web App with a misleading "unauthorized" error. Pulled the actual container logs instead of trusting the first error message, found the real cause further down (built for arm64 on my Mac, Azure runs amd64), rebuilt targeting the right platform.
- App Service Plan creation failed on a quota error. Traced it past the generic message to the specific VM family involved, confirmed via `az vm list-usage`, and found the family I'd been granted quota for wasn't the one actually being used - fixed by requesting the right one.
- Smoke test script parsed fine by eye but threw a PowerShell error the first time it actually ran (`$attempt:` inside a string). Caught because I ran it against the real deployed app before trusting it, not because I read the code carefully enough.
- Ran the vulnerability scan before and after the Spring Boot upgrade to get real numbers (43 to 25 vulnerabilities) instead of assuming the upgrade helped.

The common thread: every fix got verified by actually running it - build, deploy, curl, test - before I moved on, rather than accepting a suggested change on faith.

## Design choices

- Multi-stage Docker build, non-root user, pinned base image tags
- JaCoCo coverage gate at 70%, bound to `verify` so it's the same locally and in CI
- Managed identity instead of ACR admin credentials, scoped to just the one registry
- DB password in Key Vault, not in the pipeline YAML
- App Insights + Log Analytics wired in from the start
- Hit a real quota limit deploying dev - the trial subscription had 0 quota for the VM family App Service Plans use, and UK South had no spare capacity even after upgrading to Pay-As-You-Go, so I requested quota in UK West instead. Not a code bug, just what happens when you actually deploy something instead of only writing the Terraform
- Alert rule (>10 HTTP 5xx in 5 minutes) with an action group email notification, applied for real against dev

## What I left out, and why

1. Remote Terraform state backend - state is local for this exercise, a real team setup needs an Azure Storage backend with locking so two people can't apply at once
2. Network restrictions / WAF - the Web App is public over HTTPS, a real setup would put it behind a VNet with private endpoints and a WAF in front
3. Live Azure DevOps pipeline run - the Trivy scan still correctly blocks the pipeline (25 vulnerabilities, 6 CRITICAL, mostly in the bundled Tomcat/Jackson versions), even after upgrading off EOL Spring Boot. That's the scan doing its job, not a bug - a scanner that always passes isn't actually checking anything
<img width="1085" height="276" alt="Screenshot 2026-09-18 at 14 16 45" src="https://github.com/user-attachments/assets/52eac568-e2f0-458b-909a-a808b705928d" />



## What I'd change to run this across 38 countries

- Remote state per environment, with locking
- Request compute quota per region ahead of time - hitting a 0 quota wall on one dev environment was annoying enough, across 38 countries that needs planning not discovering last minute
- VNet integration and private endpoints with a WAF in front, instead of a public App Service URL
- Regional routing so each country's traffic lands close to it
- Centralised policy (Azure Policy / Management Groups) so the same baseline - HTTPS-only, managed identity, no admin credentials - is enforced everywhere automatically
