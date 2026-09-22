# Verify BitLocker status
Get-BitLockerVolume
manage-bde -protectors -get C:

# Suspend BitLocker
Suspend-BitLocker -MountPoint "C:" -RebootCount 2
Restart-Computer

# Resume BitLocker
Resume-BitLocker -MountPoint "C:"

# Recreate TPM protector
manage-bde -protectors -disable C:
manage-bde -protectors -delete C: -type TPM
manage-bde -protectors -add C: -tpm
manage-bde -protectors -enable C:
Restart-Computer
