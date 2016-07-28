if header['X-Spam'] == 'YES' then
    folder = "Spam"
    create_dir = true
end

if header['X-Virus'] == "YES" then
    create_dir = true
    folder = "Virus"
end

if (regex("[\\w]*@unicom.ws", header['From']) == true) then
    create_dir = true
    folder = "Mitarbeiter"
end

if (header['From'] == "cl@unicom.ws") then
    create_dir = true
    folder = "Mitarbeiter/Carina Leuthner"
end

if (header['From'] == "trinity-users-help@lists.pearsoncomputing.net" or header['To'] == "trinity-users@lists.pearsoncomputing.net") then
    create_dir = true
    folder = "TDE/users"
end

if (header['From'] == "trinity-devel-help@lists.pearsoncomputing.net" or header['To'] == "trinity-devel@lists.pearsoncomputing.net") then
    create_dir = true
    folder = "TDE/devel"
end

if (header['From'] == "trinity-commits-help@lists.pearsoncomputing.net" or header['To'] == "trinity-commits@lists.pearsoncomputing.net") then
    create_dir = true
    folder = "TDE/commits"
end

if (header['From'] == "opensuse-kde3+help@opensuse.org" or header['To'] == "opensuse-kde3@opensuse.org") then
    create_dir = true
    folder = "openSuSE/KDE3"
end

if (regex("ebay.[a-zA-Z]{2,3}", header['From']) == true) then
    create_dir = true
    folder = "eBay"
end