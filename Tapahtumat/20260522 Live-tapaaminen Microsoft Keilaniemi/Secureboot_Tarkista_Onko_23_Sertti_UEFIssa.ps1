[System.Text.Encoding]::ASCII.GetString((Get-SecureBootUEFI db).bytes) -match 'Windows UEFI CA 2023'

#True = Päivitetty sertti löytyy UEFI:sta
#False = Päivitettyä sertti ei löydy UEFI:sta