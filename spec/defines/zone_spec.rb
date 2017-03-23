require 'spec_helper'

describe 'knot::zone' do
  # by default the hiera integration uses hiera data from the shared_contexts.rb file
  # but basically to mock hiera you first need to add a key/value pair
  # to the specific context in the spec/shared_contexts.rb file
  # Note: you can only use a single hiera context per describe/context block
  # rspec-puppet does not allow you to swap out hiera data on a per test block
  # include_context :hiera

  let(:title) { 'example.com' }
  let(:node) { 'foo.example.com' }
  # below is a list of the resource parameters that you can override.
  # By default all non-required parameters are commented out,
  # while all required parameters will require you to add a value
  let(:params) do
    {
      # masters: [],
      # notify_addresses: [],
      # allow_notify: [],
      # provide_xfr: [],
      # zones: [],
      # zonefile: undef,
      # zone_dir: undef,
    }
  end
  let(:pre_condition) do
    'class { \'::knot\':
      remotes => {
        \'master\' => { \'address4\' => \'192.0.2.1\' },
        \'provide_xfr\' => { \'address4\' => \'192.0.2.2\' },
        \'allow_notify_addition\' => { \'address4\' => \'192.0.2.3\' },
        \'send_notify_addition\' => { \'address4\' => \'192.0.2.4\' },
      }
    }'
  end
  # below is the facts hash that gives you the ability to mock
  # facts on a per describe/context block.  If you use a fact in your
  # manifest you should mock the facts below.
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge(knot_version: '1.6.0')
      end
      case facts[:operatingsystem]
      when 'Ubuntu'
        let(:package_name) { 'knot' }
        let(:conf_dir)     { '/etc/knot' }
        let(:run_dir)      { '/run/knot' }
      else
        let(:package_name) { 'knot1' }
        let(:conf_dir)     { '/usr/local/etc/knot' }
        let(:run_dir)      { '/var/run/knot' }
      end
      let(:conf_file)   { "#{conf_dir}/knot.conf" }
      let(:zonesdir)    { "#{conf_dir}/zone" }
      let(:zone_subdir) { "#{zonesdir}/zone" }
      let(:pidfile)     { "#{run_dir}/knot.pid" }
      describe 'check default config' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_knot__zone('example.com') }

        it do
          is_expected.to contain_concat__fragment(
            'knot_zones_example.com'
          ).with_content(
            %r{
              "example.com"\s\{
              \s+file\s"#{zone_subdir}/example.com";
              \s+notify-out\sslave_servers;
              \s+xfr-out\sslave_servers;
              \s+\}
            }x
          )
        end
      end

      describe 'Check complete zoneset' do
        before do
          params.merge!(
            masters: ['master'],
            provide_xfrs: ['provide_xfr'],
            allow_notify_additions: ['allow_notify_addition'],
            send_notify_additions: ['send_notify_addition']
          )
        end
        it { is_expected.to compile }
        it do
          is_expected.to contain_concat__fragment(
            'knot_zones_example.com'
          ).with_content(
            %r{"example.com"\s+\{[\s\S]+notify-out\s+provide_xfr, send_notify_addition[\s\S]+\}}
          ).with_content(
            %r{"example.com"\s+\{[\s\S]+notify-in\s+master, allow_notify_addition[\s\S]+\}}
          ).with_content(
            %r{"example.com"\s+\{[\s\S]+xfr-in\s+master[\s\S]+\}}
          ).with_content(
            %r{"example.com"\s+\{[\s\S]+xfr-out\s+provide_xfr[\s\S]+\}}
          )
        end
      end

      describe 'Change Defaults' do
        context 'zonefile' do
          before { params.merge!(zonefile: 'foobar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_concat__fragment(
              'knot_zones_example.com'
            ).with_content(
              %r{"example.com"\s+\{[\s\S]+file\s+"#{zone_subdir}/foobar"[\s\S]+\}}
            )
          end
        end
        context 'zone_dir' do
          before { params.merge!(zone_dir: '/zones') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_concat__fragment(
              'knot_zones_example.com'
            ).with_content(
              %r{"example.com"\s+\{[\s\S]+file\s+"/zones/example.com"[\s\S]+\}}
            )
          end
        end
      end

      # You will have to correct any values that should be bool
      describe 'check bad type' do
        context 'masters' do
          before { params.merge!(masters: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'notify_addresses' do
          before { params.merge!(notify_addresses: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'allow_notify' do
          before { params.merge!(allow_notify: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'provide_xfr' do
          before { params.merge!(provide_xfr: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'zones' do
          before { params.merge!(zones: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'zonefile' do
          before { params.merge!(zonefile: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'zone_dir' do
          before { params.merge!(zone_dir: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
      end
    end
  end
end
