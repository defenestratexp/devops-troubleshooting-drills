    ./setup.sh
    df -h /tmp/practice-disk
    du -sh /tmp/practice-disk

df says nearly full. du says nearly empty. Reclaim the space.

Do NOT reboot, do not unmount, and do not recreate the filesystem. When you are
done, ./verify.sh should pass. Then write down the one command that would have
told you the answer in under ten seconds.

Cleanup when finished:  sudo umount /tmp/practice-disk; rm -f /tmp/practice-disk.img
