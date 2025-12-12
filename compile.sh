# 1. Compile (passing flags to linker)
swiftc main.swift -o wifi_scanner -Xlinker -sectcreate -Xlinker __TEXT -Xlinker __info_plist -Xlinker Info.plist

# 2. Sign the binary (ensures the OS reads the plist correctly)
codesign -f -s - wifi_scanner