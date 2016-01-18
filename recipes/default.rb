#
# Cookbook Name:: IIS_GIT_SITE
# Recipe:: default
#
# Copyright (c) 2016 The Authors, All Rights Reserved.
# Supported OS - Windows Server 2012 R2

# Install IIS role with PowerShell DSC
dsc_script 'Web-Server' do
  code <<-EOH
  WindowsFeature InstallWebServer
  {
    Name = "Web-Server"
    Ensure = "Present"
  }
  EOH
end

# Install the IIS Management Console.
dsc_script 'Web-Mgmt-Console' do
  code <<-EOH
  WindowsFeature InstallIISConsole
  {
    Name = "Web-Mgmt-Console"
    Ensure = "Present"
  }
  EOH
end

# Install IIS CGI - PHP depends on this.
dsc_script 'Web-CGI' do
  code <<-EOH
  WindowsFeature InstallIISConsole
  {
    Name = "Web-CGI"
    Ensure = "Present"
  }
  EOH
end

# download php to directory
remote_file 'C:\chef\cache\php.msi' do
  source 'http://windows.php.net/downloads/releases/archives/php-5.3.9-Win32-VC9-x86.msi'
end

# run msiexec to install
powershell_script 'Install PHP' do
  code <<-EOH
    msiexec.exe /i C:\\chef\\cache\\php.msi /q ADDLOCAL=cgi
  EOH
  not_if <<-EOH
    $foo = (Get-WmiObject -class Win32_Product | Where-Object
      { $_.Name -eq "PHP 5.3.9"})
    if ($foo)
    {
      return $true
    }
    else
    {
      return $false
    }
  EOH
end

remote_file 'C:\chef\cache\git.exe' do
  source 'https://github.com/git-for-windows/git/releases/download/v2.7.0.windows.1/Git-2.7.0-64-bit.exe'
end

# Install git
powershell_script 'Install git' do
  code <<-EOH
    c:\\chef\\cache\\git.exe /verysilent
    $env:Path += ';C:\\Program Files\\Git\\bin'
  EOH
  not_if <<-EOH
    Test-Path 'C:\\Program Files\\Git'
  EOH
end

# pull down repo if there are differences
powershell_script 'Pull down on git repo' do
  code <<-EOH
    git pull https://github.com/mostateresnet/resnet.missouristate.edu.git
      c:\\inetpub\\wwwroot\\
  EOH
  not_if <<-EOH
    set-location -Path c:\inetpub\wwwroot\
    git fetch
    $foo = $(git status | findstr "up-to-date")
    if ($foo)
    {
      return $false
    }
    else
    {
      return $true
    }
  EOH
end
