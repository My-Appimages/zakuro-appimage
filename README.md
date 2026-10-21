<img width="256" height="256" alt="Zakuro@2x" src="https://github.com/user-attachments/assets/5b582dbf-c21d-4cd8-ade4-444e7d8c4def" />

An unofficial appimage for [Zakuro](https://github.com/fearkov/zakuro/releases)

# How is the AppImage built
1. It runs an Github action that will run the build-appimage-ubuntu.sh script to build the AppImage.
3. Then after succesfully building it will create a Github release and uploads the output AppImage.

# What's the purpose of this repository?
1. Zakuro updates very frequently as it is still in alpha stage and so downloading the binary every time is tedious
2. To conveniently update Zakuro through [Gear Lever.](https://github.com/mijorus/gearlever)
3. To learn how AppImages are being built and distributed.

# Why reinvent the wheel?
While other platforms, already exist i made this repository purely as a learning experience and fun.

> Safety note
> This repository's Github Action workflow currently does not verify the integrity of the upstream binary. proceed with caution
> If the upstream binary or workflow ends up being compromised, the AppImage here could contain malicious code. use this at your own risk!
> The good thing is i can at least vet the binary before manually running the workflow, but security is still not guaranteed and AppImage may be out of date.
