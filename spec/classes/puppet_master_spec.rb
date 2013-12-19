require 'spec_helper'

describe 'puppet::master', :type => :class do

    context 'on Debian operatingsystems' do
        let(:facts) do
            {
                :osfamily        => 'Debian',
                :operatingsystem => 'Debian',
                :operatingsystemrelease => '5',
                :concat_basedir => '/nde',
            }
        end
        let (:params) do
            {
                :version                => 'present',
                :puppet_master_package  => 'puppetmaster',
                :puppet_master_service  => 'puppetmaster',
                :modulepath             => '/etc/puppet/modules',
                :manifest               => '/etc/puppet/manifests/site.pp',
                :autosign               => 'true',
                :certname               => 'test.example.com',
                :storeconfigs           => 'true',
                :storeconfigs_dbserver  => 'test.example.com',
            }
        end
        it { should contain_class('puppet::params') }
        it {
            Puppet::Util::Log.level = :debug
            Puppet::Util::Log.newdestination(:console)
            should contain_user('puppet').with(
                :ensure => 'present',
                :uid    => nil,
                :gid    => 'puppet'
            )
            should contain_group('puppet').with(
                :ensure => 'present',
                :gid    => nil
            )
            should contain_package(params[:puppet_master_package]).with(
                :ensure => params[:version],
                :require => 'Package[puppetmaster-common]'
            )
            should contain_package('puppetmaster-common').with(
                :ensure => params[:version]
            )
            should contain_service(params[:puppet_master_service]).with(
                :ensure    => 'stopped',
                :enable    => 'false',
                :require   => 'File[/etc/puppet/puppet.conf]'
            )
            should contain_file('/etc/puppet/puppet.conf').with(
                :ensure  => 'file',
                :require => 'File[/etc/puppet]',
                :owner   => 'puppet',
                :group   => 'puppet',
                :notify  => 'Service[httpd]'
            )
            should contain_file('/etc/puppet').with(
                :require => "Package[#{params[:puppet_master_package]}]",
                :ensure => 'directory',
                :owner  => 'puppet',
                :group  => 'puppet',
                :notify => "Service[httpd]"
            )
            should contain_file('/var/lib/puppet').with(
                :ensure => 'directory',
                :owner  => 'puppet',
                :group  => 'puppet',
                :notify => 'Service[httpd]'
            )
            should contain_class('puppet::storeconfigs').with(
              :before => 'Anchor[puppet::master::end]'
            )
            should contain_class('puppet::passenger').with(
              :before => 'Anchor[puppet::master::end]'
            )
            should contain_ini_setting('puppetmastermodulepath').with(
                :ensure  => 'present',
                :section => 'master',
                :setting => 'modulepath',
                :path    => '/etc/puppet/puppet.conf',
                :value   => params[:modulepath],
                :require => 'File[/etc/puppet/puppet.conf]'
            )
            should contain_ini_setting('puppetmastermanifest').with(
                :ensure  => 'present',
                :section => 'master',
                :setting => 'manifest',
                :path    => '/etc/puppet/puppet.conf',
                :value   => params[:manifest],
                :require => 'File[/etc/puppet/puppet.conf]'
            )
            should contain_ini_setting('puppetmasterautosign').with(
                :ensure  => 'present',
                :section => 'master',
                :setting => 'autosign',
                :path    => '/etc/puppet/puppet.conf',
                :value   => params[:autosign],
                :require => 'File[/etc/puppet/puppet.conf]'
            )
            should contain_ini_setting('puppetmastercertname').with(
                :ensure  => 'present',
                :section => 'master',
                :setting => 'certname',
                :path    => '/etc/puppet/puppet.conf',
                :value   => params[:certname],
                :require => 'File[/etc/puppet/puppet.conf]'
            )
            should contain_ini_setting('puppetmasterreports').with(
                :ensure  => 'present',
                :section => 'master',
                :setting => 'reports',
                :path    => '/etc/puppet/puppet.conf',
                :value   => 'store',
                :require => 'File[/etc/puppet/puppet.conf]'
            )
            should contain_ini_setting('puppetmasterparser').with(
                :ensure  => 'present',
                :section => 'master',
                :setting => 'parser',
                :path    => '/etc/puppet/puppet.conf',
                :value   => 'current',
                :require => 'File[/etc/puppet/puppet.conf]'
            )
            should contain_ini_setting('puppetmasterpluginsync').with(
                :ensure  => 'present',
                :section => 'master',
                :setting => 'pluginsync',
                :path    => '/etc/puppet/puppet.conf',
                :value   => 'true'
            )
            should contain_anchor('puppet::master::begin').with_before(
              ['Class[Puppet::Passenger]', 'Class[Puppet::Storeconfigs]']
            )
            should contain_anchor('puppet::master::end')
        }
         it {
                should contain_class('apache')
                should contain_class('puppet::params')
                should contain_class('apache::mod::passenger')
                should contain_class('apache::mod::ssl')
                should contain_exec('Certificate_Check').with(
                    :command =>
                      "puppet cert clean #{params[:certname]} ; " +
                      "puppet certificate --ca-location=local --dns_alt_names=puppet generate #{params[:certname]}" +
                      " && puppet cert sign --allow-dns-alt-names #{params[:certname]}" +
                      " && puppet certificate --ca-location=local find #{params[:certname]}",
                    :unless  => "/bin/ls /var/lib/puppet/ssl/certs/#{params[:certname]}.pem",
                    :path    => '/usr/bin:/usr/local/bin',
                    :require  => "File[/etc/puppet/puppet.conf]"
                )
                should contain_file('/etc/puppet/rack/public/').with(
                    :ensure => 'directory',
                    :owner  => 'puppet',
                    :group  => 'puppet',
                    :mode   => '0755'
                )
                should contain_file('/etc/puppet/rack').with(
                    :ensure => 'directory',
                    :owner  => 'puppet',
                    :group  => 'puppet',
                    :mode   => '0755'
                )
                 should contain_file('/etc/puppet/rack/config.ru').with(
                    :ensure => 'present',
                    :owner  => 'puppet',
                    :group  => 'puppet',
                    :mode   => '0644'
                )
                should contain_ini_setting('puppetmastersslclient').with(
                    :ensure  => 'present',
                    :section => 'master',
                    :setting => 'ssl_client_header',
                    :path    => '/etc/puppet/puppet.conf',
                    :value   =>'SSL_CLIENT_S_DN',
                    :require => "File[/etc/puppet/puppet.conf]"
                )
                should contain_ini_setting('puppetmastersslclientverify').with(
                    :ensure  => 'present',
                    :section => 'master',
                    :setting => 'ssl_client_verify_header',
                    :path    => '/etc/puppet/puppet.conf',
                    :value   =>'SSL_CLIENT_VERIFY',
                    :require => "File[/etc/puppet/puppet.conf]"
                )
        }
    end

    context 'on RedHat operatingsystems' do
        let(:facts) do
            {
                :osfamily        => 'RedHat',
                :operatingsystem => 'RedHat',
                :operatingsystemrelease => '6',
                :concat_basedir => '/nde',
            }
        end
        let (:params) do
            {
                :version                => 'present',
                :puppet_master_package  => 'puppetmaster',
                :puppet_master_service  => 'puppetmaster',
                :modulepath             => '/etc/puppet/modules',
                :manifest               => '/etc/puppet/manifests/site.pp',
                :autosign               => 'true',
                :certname               => 'test.example.com',
                :storeconfigs           => 'true',
                :storeconfigs_dbserver  => 'test.example.com'

            }
        end
        it {
            should contain_user('puppet').with(
                :ensure => 'present',
                :uid    => nil,
                :gid    => 'puppet'
            )
            should contain_group('puppet').with(
                :ensure => 'present',
                :gid    => nil
            )
            should contain_package(params[:puppet_master_package]).with(
                :ensure => params[:version],
            )
            should_not contain_package('puppetmaster-common').with(
                :ensure => params[:version]
            )
            should contain_service(params[:puppet_master_service]).with(
                :ensure    => 'stopped',
                :enable    => 'false',
                :require   => 'File[/etc/puppet/puppet.conf]'
            )
            should contain_file('/etc/puppet/puppet.conf').with(
                :ensure  => 'file',
                :require => 'File[/etc/puppet]',
                :owner   => 'puppet',
                :group   => 'puppet',
                :notify  => 'Service[httpd]'
            )
            should contain_file('/etc/puppet').with(
                :require => "Package[#{params[:puppet_master_package]}]",
                :ensure => 'directory',
                :owner  => 'puppet',
                :group  => 'puppet',
                :notify => "Service[httpd]"
            )
            should contain_file('/var/lib/puppet').with(
                :ensure => 'directory',
                :owner  => 'puppet',
                :group  => 'puppet',
                :notify => 'Service[httpd]'
            )
            should contain_class('puppet::storeconfigs').with(
              :before => 'Anchor[puppet::master::end]'
            )
            should contain_class('puppet::passenger').with(
              :before => 'Anchor[puppet::master::end]'
            )
            should contain_ini_setting('puppetmastermodulepath').with(
                :ensure  => 'present',
                :section => 'master',
                :setting => 'modulepath',
                :path    => '/etc/puppet/puppet.conf',
                :value   => params[:modulepath],
                :require => 'File[/etc/puppet/puppet.conf]'
            )
            should contain_ini_setting('puppetmastermanifest').with(
                :ensure  => 'present',
                :section => 'master',
                :setting => 'manifest',
                :path    => '/etc/puppet/puppet.conf',
                :value   => params[:manifest],
                :require => 'File[/etc/puppet/puppet.conf]'
            )
            should contain_ini_setting('puppetmasterautosign').with(
                :ensure  => 'present',
                :section => 'master',
                :setting => 'autosign',
                :path    => '/etc/puppet/puppet.conf',
                :value   => params[:autosign],
                :require => 'File[/etc/puppet/puppet.conf]'
            )
            should contain_ini_setting('puppetmastercertname').with(
                :ensure  => 'present',
                :section => 'master',
                :setting => 'certname',
                :path    => '/etc/puppet/puppet.conf',
                :value   => params[:certname],
                :require => 'File[/etc/puppet/puppet.conf]'
            )
            should contain_ini_setting('puppetmasterreports').with(
                :ensure  => 'present',
                :section => 'master',
                :setting => 'reports',
                :path    => '/etc/puppet/puppet.conf',
                :value   => 'store',
                :require => 'File[/etc/puppet/puppet.conf]'
            )
            should contain_ini_setting('puppetmasterparser').with(
                :ensure  => 'present',
                :section => 'master',
                :setting => 'parser',
                :path    => '/etc/puppet/puppet.conf',
                :value   => 'current',
                :require => 'File[/etc/puppet/puppet.conf]'
            )
            should contain_ini_setting('puppetmasterpluginsync').with(
                :ensure  => 'present',
                :section => 'master',
                :setting => 'pluginsync',
                :path    => '/etc/puppet/puppet.conf',
                :value   => 'true'
            )
            should contain_anchor('puppet::master::begin').with_before(
              ['Class[Puppet::Passenger]', 'Class[Puppet::Storeconfigs]']
            )
            should contain_anchor('puppet::master::end')
        }
         it {
                should contain_file('/var/lib/puppet/reports')
                should contain_file('/var/lib/puppet/ssl/ca/requests')
        }
    end
end
