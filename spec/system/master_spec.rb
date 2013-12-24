require 'spec_helper_system'

case node.facts['osfamily']
when 'Debian'
    apache_service = 'apache2'
when 'RedHat'
    apache_service = 'httpd'
else
    fail "Apache service name not known for osfamily #{node.facts['osfamily']}"
end

describe 'master tests:' do
    it 'make sure we have copied the module across' do
        # No point diagnosing any more if the module wasn't copied properly
        shell("ls /etc/puppet/modules/puppet") do |r|
            r[:exit_code].should == 0
            r[:stdout].should =~ /Modulefile/
            r[:stderr].should == ''
        end
    end

    context 'with remote CA' do
        it 'puppet::master class should work with no errors' do
            pp = <<-EOS
                class { 'puppet::master':
                    puppetca_enabled        => false,
                    puppet_master_ca_server => 'puppetca.foo.local',
                }
            EOS
            # Run it twice and test for idempotency
            puppet_apply(pp) do |r|
                r.exit_code.should_not == 1
                r.refresh
                r.exit_code.should be_zero
            end
        end

        describe service(apache_service) do
            it { should be_enabled }
            it { should be_running }
        end
    end

    context 'without puppetdb' do
        it 'puppet::master class should work with no errors' do
            pp = <<-EOS
                class { 'puppet::master': }
            EOS

            # Run it twice and test for idempotency
            puppet_apply(pp) do |r|
                r.exit_code.should_not == 1
                r.refresh
                r.exit_code.should be_zero
            end
        end

        describe service(apache_service) do
            it { should be_enabled }
            it { should be_running }
        end
    end

    context 'with external puppetdb' do
        it 'puppet::master class should work with no errors' do
            pp = <<-EOS
                class { 'puppet::master':
                    storeconfigs               => true,
                    storeconfigs_dbserver      => 'puppetdb.foo.local',
                    puppetdb_strict_validation => false,
                }
            EOS

            # Run it twice and test for idempotency
            puppet_apply(pp) do |r|
                r.exit_code.should_not == 1
                r.refresh
                r.exit_code.should be_zero
            end
        end

        describe service(apache_service) do
            it { should be_enabled }
            it { should be_running }
        end
    end

    # This test has to be after the non-puppetdb tests
    context 'with puppetdb' do
        it 'puppet::master class should work with no errors' do
            pp = <<-EOS
                class { 'puppetdb': }
                class { 'puppet::master':
                    storeconfigs               => true,
                }
            EOS

            # Run it twice and test for idempotency
            puppet_apply(pp) do |r|
                r.exit_code.should_not == 1
                r.refresh
                r.exit_code.should be_zero
            end
        end

        describe service(apache_service) do
            it { should be_enabled }
            it { should be_running }
        end

        describe service('puppetdb') do
            it { should be_enabled }
            it { should be_running }
        end
    end
end
