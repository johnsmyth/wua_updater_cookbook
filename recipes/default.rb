#
# Author:: Doug MacEachern <dougm@vmware.com>
# Cookbook Name:: windows
# Recipe:: update
#
# Copyright 2010, VMware, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#download and install windows updates
#ruby_block 'install updates' do
#  block do
    #adapted from http://msdn.microsoft.com/en-us/library/aa387102%28VS.85%29.aspx
    require 'win32ole'
    
    session = WIN32OLE.new("Microsoft.Update.Session")
    searcher = session.CreateUpdateSearcher
    updates_query = "IsInstalled=0 and Type='Software' and AutoSelectOnWebSites=1" #XXX make this an attribute?
    Chef::Log.debug("Searching for updates...")
     puts "Searching for updates..."
    required_updates = searcher.search(updates_query)
    
    if required_updates.updates.count > 0
      updates_to_download = WIN32OLE.new("Microsoft.Update.UpdateColl")
    
    
      required_updates.updates.each do |update|
        Chef::Log.debug("Required update found: #{update.title}")
        puts "Required update found: #{update.title}"

        updates_to_download.add(update) unless update.isdownloaded
        update.AcceptEula unless update.EulaAccepted
      end
    
      if updates_to_download.count > 0
        Chef::Log.info("Downloading #{updates_to_download.count} updates (this may take a long time)...")
        puts "Downloading #{updates_to_download.count} updates (this may take a long time)..."
    
        downloader = session.CreateUpdateDownloader
        downloader.updates = updates_to_download
        downloader.download
      end
    
      updates_to_install = WIN32OLE.new("Microsoft.Update.UpdateColl")
    
      required_updates.updates.each do |update|
        updates_to_install.add(update) if update.isdownloaded
      end
    
      Chef::Log.info("Installing #{updates_to_install.count} updates (this may take a long time)...")
      puts "Installing #{updates_to_install.count} updates (this may take a long time)..."

      installer = session.CreateUpdateInstaller
      installer.updates= updates_to_install 
      install_result = installer.install
    	
      puts "Installation Result: #{install_result.ResultCode}"
      Chef::Log.debug("Installation Result: #{install_result.ResultCode}")
    
      if install_result.RebootRequired
        Chef::Log.warn("REBOOT IS REQUIRED")
         puts "REBOOT IS REQUIRED"
    #    WMI::Win32_OperatingSystem.find(:first).reboot
      else
        Chef::Log.debug("No reboot required")
        puts "No reboot required"
      end
    else
      Chef::Log.info("No updates available")
      puts "No updates available"
    end
#  end
#end
