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
  config.vm.box = 'bento/ubuntu-18.04'

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
