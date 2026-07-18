# OmniRoute Android/Termux production build harness

This repository builds the official OmniRoute `release/v3.8.49` branch on a GitHub-hosted ARM64 runner and uploads a portable `.next` production artifact for Android Termux validation.

Target workflow:

1. GitHub Actions builds OmniRoute on `ubuntu-24.04-arm`.
2. The workflow uploads `omniroute-production-termux.tar.gz`.
3. The tarball is downloaded to Mac and then transferred to the Android Termux device.
4. The phone keeps its own Android/Termux `node_modules`; only the production `.next` output is replaced.
5. The phone runs `next start` instead of `next dev` to avoid runtime route compilation.

The first goal is validation, not a guaranteed final deployment: GitHub ARM64 is Linux/glibc, while the phone is Android/bionic. Native `node_modules` should not be copied from the runner to the phone.
