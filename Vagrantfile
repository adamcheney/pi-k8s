# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'fileutils'

FOLDERS = %w[
  packer
  packer_cache
  output
].map(&:freeze).freeze

FOLDERS.each do |folder|
  FileUtils.mkdir_p(File.join(File.dirname(__FILE__), folder))
end

Vagrant.configure('2') do |config|
  config.vm.box = 'bento/ubuntu-20.04'
  config.vm.define "pi_imagemaker"
  config.vm.provider "virtualbox" do |vb|
    vb.name = "pi_imagemaker"
    vb.gui = false
      vb.customize [ "modifyvm", :id, "--uartmode1", "disconnected" ]
  end
  config.vm.provision "shell",
    inline: "chmod 700 /home/vagrant"
  FOLDERS.each do |folder|
    config.vm.synced_folder folder, "/home/vagrant/#{folder}"
  end

  Dir.glob('vagrant/provision/*.sh').sort.each do |script|
    config.vm.provision script,
                        type: :shell,
                        path: script,
                        privileged: false
  end
end
