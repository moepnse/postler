if (X-Spam == "YES") then
    set create dir = True
    set folder = "Spam"
end if

if (X-Virus == "YES") then
    set create dir = True
    set folder = "Virus"
end if

if (regex("[\w]*@unicom.ws", From) == True) then
    set create dir = True
    set folder = "Mitarbeiter"
end if

if (From == "cl@unicom.ws") then
    set create dir = True
    set folder = "Mitarbeiter/Carina Leuthner"
end if

if (From == "trinity-users-help@lists.pearsoncomputing.net" or To == "trinity-users@lists.pearsoncomputing.net") then
    set create dir = True
    set folder = "TDE/users"
end if

if (From == "trinity-devel-help@lists.pearsoncomputing.net" or To == "trinity-devel@lists.pearsoncomputing.net") then
    set create dir = True
    set folder = "TDE/devel"
end if

if (From == "trinity-commits-help@lists.pearsoncomputing.net" or To == "trinity-commits@lists.pearsoncomputing.net") then
    set create dir = True
    set folder = "TDE/commits"
end if

if (From == "opensuse-kde3+help@opensuse.org" or To == "opensuse-kde3@opensuse.org") then
    set create dir = True
    set folder = "openSuSE/KDE3"
end if

if (regex("ebay.[a-zA-Z]{2,3}", From) == True) then
    set create dir = True
    set folder = "eBay"
end if

if (regex("willhaben.at", From) == True) then
    set create dir = True
    set folder = "willhaben"
end if

if (regex("info@bmd-baustoffe.de", From) == True) then
    set create dir = True
    set folder = "BMD Baustoffe"
end if
