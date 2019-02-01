# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Trav3::Travis, :vcr do
  let(:t) { build :travis }

  describe '#new' do
    context 'happy path' do
      it 'returns a valid instance' do
        expect(t).to be_an_instance_of Trav3::Travis
      end

      it 'has good repo name' do
        expect(t.send(:repository_name)).to eq 'danielpclark%2Ftrav3'
      end

      it 'has default headers' do
        accept = t.headers.fetch(:Accept)
        expect(accept).to eql('application/json')
      end

      it 'has default options' do
        limit = t.options.fetch(:limit)
        expect(limit).to eql('limit=25')
      end
    end

    context 'unhappy path' do
      let(:travis) { Trav3::Travis.new('asdf-asdf') }
      it 'raises Trav3::InvalidRepository when invalid' do
        expect { travis }.to raise_error(Trav3::InvalidRepository, /invalid/)
      end
    end
  end

  describe '#api_endpoint=' do
    it 'sets the API endpoint' do
      t.api_endpoint = 'https://api.travis-ci.com'
      expect(t.api_endpoint).to eq 'https://api.travis-ci.com'
    end

    it 'raises on invalid API endpoint' do
      expect { t.api_endpoint = 'https://asdf.qwerty' }.to raise_error(Trav3::InvalidAPIEndpoint, /API/)
    end
  end

  describe '#defaults' do
    it 'also sets options via kwargs' do
      t.defaults(asdf: :qwerty)
      o = t.options.fetch(:asdf)
      expect(o).to eql('asdf=qwerty')
    end
  end

  describe '#h' do
    it 'also sets headers via kwargs' do
      t.h(asdf: :qwerty)
      h = t.headers.fetch(:asdf)
      expect(h).to eql(:qwerty)
    end
  end

  describe '#active' do
    it 'gets current users active builds' do
      active = t.active
      expect(active).to be_an_instance_of Trav3::Success
    end

    it 'gets active builds for a user id' do
      active = t.active(639_823)
      expect(active).to be_an_instance_of Trav3::Success
    end
  end

  describe '#beta_feature' do
    before do
      t.api_endpoint = 'https://api.travis-ci.com'
      t.authorization = 'xxxx'
    end

    it 'updates and enables a beta feature' do
      bf = t.beta_feature(:enable, 3, 119_240)
      expect(bf).to be_an_instance_of Trav3::Success
    end

    it 'updates and disables a beta feature' do
      bf = t.beta_feature(:disable, 3, 119_240)
      expect(bf).to be_an_instance_of Trav3::Success
    end

    it 'deletes a beta feature' do
      t.beta_feature(:enable, 2, 119_240)
      bf = t.beta_feature(:delete, 2, 119_240)
      expect(bf).to be_an_instance_of Trav3::Success
    end
  end

  describe '#beta_features' do
    before do
      t.api_endpoint = 'https://api.travis-ci.com'
      t.authorization = 'xxxx'
    end

    it 'gets the beta features for a user' do
      bf = t.beta_features(119_240)
      expect(bf).to be_an_instance_of Trav3::Success
    end
  end

  describe '#branch' do
    it 'gets the branch for the current repository' do
      branch = t.branch('master')
      expect(branch).to be_an_instance_of Trav3::Success
    end
  end

  describe '#branches' do
    it 'gets the branches for the current repository' do
      branches = t.branches
      expect(branches).to be_an_instance_of Trav3::Success
    end
  end

  describe '#broadcasts' do
    it 'gets broadcasts for the current user' do
      broadcasts = t.broadcasts
      expect(broadcasts).to be_an_instance_of Trav3::Success
    end
  end

  describe '#build' do
    it 'gets build info' do
      build = t.build(351_778_872)
      expect(build).to be_an_instance_of Trav3::Success
    end

    it 'restarts a build' do
      build = t.build(478_772_528, :restart)
      expect(build).to be_an_instance_of Trav3::Success
    end

    it 'cancels a build' do
      build = t.build(478_772_528, :cancel)
      expect(build).to be_an_instance_of Trav3::Success
    end
  end

  describe '#builds', vcr: { cassette_name: 'Trav3_Travis/_builds', record: :new_episodes } do
    it 'gets collection of builds' do
      builds = t.builds
      expect(builds['builds'].count).to be 25
    end

    it 'has pages of builds' do
      builds = t.builds
      expect(builds.page.next['builds'].count).to be > 10
    end

    it 'has a first page' do
      builds = t.builds
      expect(builds.page.first['builds'].count).to be 25
    end

    it 'has a last page' do
      builds = t.builds
      expect(builds.page.last['builds'].count).to be > 10
    end

    it 'gets all builds for current user' do
      builds = t.builds(false)
      expect(builds['builds'].count).to be 25
    end
  end

  describe '#build_jobs' do
    it 'gets build job details for build' do
      build_jobs = t.build_jobs(351_778_872)
      expect(build_jobs).to be_an_instance_of Trav3::Success
    end

    it 'gets jobs for user' do
      build_jobs = t.build_jobs(false)
      expect(build_jobs).to be_an_instance_of Trav3::Success
    end
  end

  describe '#caches', vcr: { cassette_name: 'Trav3_Travis/_caches', record: :new_episodes } do
    it 'gets caches for the current repository' do
      caches = t.caches
      expect(caches).to be_an_instance_of Trav3::Success
    end

    it 'deletes the cache' do
      expect do
        t.options.reset!
        response = t.caches(:delete)
        expect(response).to be_an_instance_of Trav3::Success
      end.to change { t.caches['caches'].count }.to(0)
    end
  end

  describe '#cron' do
    context 'on a branch' do
      it 'creates a cron job' do
        c = t.cron(branch_name: 'master', create: { 'interval' => 'weekly' })
        expect(c).to be_an_instance_of Trav3::Success
      end

      it 'creates a cron job with travis style params' do
        c = t.cron(branch_name: 'master', create: { 'cron.interval' => 'weekly' })
        expect(c).to be_an_instance_of Trav3::Success
      end

      it 'gets a cron job' do
        c = t.cron(branch_name: 'master')
        expect(c).to be_an_instance_of Trav3::Success
      end
    end

    context 'for a specific cron' do
      it 'finds a cron' do
        c = t.cron(id: 78_199)
        expect(c).to be_an_instance_of Trav3::Success
      end

      it 'deletes a cron' do
        c = t.cron(id: 78_199, delete: true)
        expect(c).to be_an_instance_of Trav3::Success
      end
    end
  end

  describe '#crons' do
    it 'gets crons for an individual repository' do
      t.options.reset!
      crons = t.crons
      expect(crons).to be_an_instance_of Trav3::Success
    end
  end

  describe '#email_resubscribe' do
    it 'resubscribes to receiving email for build status' do
      sub = t.email_resubscribe
      expect(sub).to be_an_instance_of Trav3::Success
    end
  end

  describe '#email_unsubscribe' do
    it 'unsubscribes for receiving email for build status' do
      sub = t.email_unsubscribe
      expect(sub).to be_an_instance_of Trav3::Success
    end
  end

  describe '#env_var' do
    it 'finds an env var' do
      ev = t.env_var('76f9d8bd-642d-47ed-9f35-4c25eb030c6c')
      expect(ev).to be_an_instance_of Trav3::Success
    end

    it 'updates an env var' do
      ev = t.env_var('76f9d8bd-642d-47ed-9f35-4c25eb030c6c', update: { value: 'Baz' })
      expect(ev).to be_an_instance_of Trav3::Success
    end

    it 'deletes an env var' do
      ev = t.env_var('76f9d8bd-642d-47ed-9f35-4c25eb030c6c', delete: true)
      expect(ev).to be_an_instance_of Trav3::Success
    end
  end

  describe '#env_vars' do
    it 'gets env vars' do
      ev = t.env_vars
      expect(ev).to be_an_instance_of Trav3::Success
    end

    it 'creates an environment variable' do
      ev = t.env_vars(name: 'Foo', value: 'Bar', public: true)
      expect(ev).to be_an_instance_of Trav3::Success
    end
  end

  describe '#installation' do
    before do
      t.api_endpoint = 'https://api.travis-ci.com'
      t.authorization = 'xxxx'
    end

    it 'returns a single installation' do
      installation = t.installation(617_754)
      expect(installation).to be_an_instance_of Trav3::Success
    end
  end

  describe '#job' do
    it 'gets job info' do
      job = t.job(351_778_875)
      expect(job).to be_an_instance_of Trav3::Success
    end

    it 'restarts the job' do
      job = t.job(351_778_875, :restart)
      expect(job).to be_an_instance_of Trav3::Success
    end

    it 'cancels the job' do
      job = t.job(351_778_875, :cancel)
      expect(job).to be_an_instance_of Trav3::Success
    end

    it 'use debug mode on job' do
      t.api_endpoint = 'https://api.travis-ci.com'
      t.authorization = 'xxxx'

      job = t.job(173_173_524, :debug)
      expect(job).to be_an_instance_of Trav3::Success
    end
  end

  describe '#key_pair' do
    before do
      t.repository = 'danielpclark/xxxxx'
      t.api_endpoint = 'https://api.travis-ci.com'
      t.authorization = 'xxxx'
    end

    it 'creates current key pair' do
      kp = t.key_pair(create: { description: 'FooBarBaz', value: OpenSSL::PKey::RSA.generate(2048).to_s })
      expect(kp).to be_an_instance_of Trav3::Success
    end

    it 'gets current key pair' do
      kp = t.key_pair
      expect(kp).to be_an_instance_of Trav3::Success
    end

    it 'updates current key pair' do
      kp = t.key_pair(update: { description: 'Foo Bar Baz' })
      expect(kp).to be_an_instance_of Trav3::Success
    end

    it 'deletes current key pair' do
      kp = t.key_pair(delete: true)
      expect(kp).to be_an_instance_of Trav3::Success
    end
  end

  describe '#key_pair_generated' do
    it 'gets current generated key pair' do
      kp = t.key_pair_generated
      expect(kp).to be_an_instance_of Trav3::Success
    end

    it 'generates a key pair' do
      kp = t.key_pair_generated(:create)
      expect(kp).to be_an_instance_of Trav3::Success
    end
  end

  describe '#lint' do
    it 'lints the travis.yml file' do
      lint = t.lint(File.read('.travis.yml'))
      expect(lint).to be_an_instance_of Trav3::Success
    end
  end

  describe '#log' do
    it 'gets log of job' do
      log = t.log(351_778_875)
      expect(log).to be_an_instance_of Trav3::Success
    end

    it 'gets text of log of job' do
      log = t.log(351_778_875, :text)
      expect(log).to be_an_instance_of String
      expect(log).to include('Worker information')
    end

    it 'deletes a log entry' do
      log = t.log(478_772_530, :delete)
      expect(log).to be_an_instance_of Trav3::Success
    end
  end

  describe '#messages' do
    it 'gets messages for a request' do
      messages = t.messages(147_731_561)
      expect(messages).to be_an_instance_of Trav3::Success
      expect(messages['messages']).to be_empty
    end
  end

  describe '#owner' do
    it 'gets the owner of a name' do
      owner = t.owner('danielpclark')
      expect(owner).to be_an_instance_of Trav3::Success
    end

    it 'gets the owner of an github_id' do
      owner = t.owner(639_823)
      expect(owner).to be_an_instance_of Trav3::Success
    end
  end

  describe '#organization' do
    it 'gets organization details' do
      organization = t.organization(87)
      expect(organization).to be_an_instance_of Trav3::Success
    end
  end

  describe '#organizations' do
    it 'gets organizations for current user' do
      t.options.reset!
      organizations = t.organizations
      expect(organizations).to be_an_instance_of Trav3::Success
    end
  end

  describe '#preference' do
    context 'for user' do
      it 'gets a preference' do
        preference = t.preference('build_emails')
        expect(preference).to be_an_instance_of Trav3::Success
      end

      it 'sets a preference' do
        preference = t.preference('build_emails', true)
        expect(preference).to be_an_instance_of Trav3::Success
      end
    end

    context 'for organization' do
      it 'gets a preference' do
        preference = t.preference('private_insights_visibility', org_id: 107_660)
        expect(preference).to be_an_instance_of Trav3::Success
      end

      it 'sets a preference' do
        preference = t.preference('private_insights_visibility', 'admins', org_id: 107_660)
        expect(preference).to be_an_instance_of Trav3::Success
      end
    end
  end

  describe '#preferences' do
    it 'gets preferences' do
      preferences = t.preferences
      expect(preferences).to be_an_instance_of Trav3::Success
    end

    it 'gets preferences for an organization' do
      preferences = t.preferences(107_660)
      expect(preferences).to be_an_instance_of Trav3::Success
    end
  end

  describe '#repositories' do
    it 'gets collection of repositories for username' do
      repositories = t.repositories
      expect(repositories['repositories'].count).to be 25
    end

    it 'gets collection of repositories for user_id' do
      repositories = t.repositories(639_823)
      expect(repositories['repositories'].count).to be 25
    end
  end

  describe '#repository' do
    it 'gets repository info' do
      repository = t.repository('danielpclark/trav3')
      expect(repository).to be_an_instance_of Trav3::Success
    end

    it 'accepts an action for the repository' do
      repository = t.repository('danielpclark/trav3', 'unstar')
      expect(repository).to be_an_instance_of Trav3::Success
    end
  end

  describe '#request' do
    it 'gets details of a request' do
      request = t.request(147_776_757)
      expect(request).to be_an_instance_of Trav3::Success
    end
  end

  describe '#requests' do
    it 'gets requests details' do
      requests = t.requests
      expect(requests).to be_an_instance_of Trav3::Success
    end

    it 'sets some requests details' do
      requests = t.requests(
        'message': 'Override the commit message: this is an api request',
        'branch': 'master'
      )
      expect(requests).to be_an_instance_of Trav3::Success
    end
  end

  describe '#setting' do
    it 'gets a setting' do
      setting = t.setting('auto_cancel_pull_requests')
      expect(setting).to be_an_instance_of Trav3::Success
    end

    it 'sets a setting' do
      setting = t.setting('auto_cancel_pull_requests', false)
      expect(setting).to be_an_instance_of Trav3::Success
    end
  end

  describe '#settings' do
    it 'gets settings' do
      settings = t.settings
      expect(settings).to be_an_instance_of Trav3::Success
    end
  end

  describe '#stages' do
    it 'gets build stages' do
      stages = t.stages(479_113_572)
      expect(stages).to be_an_instance_of Trav3::Success
    end
  end

  describe '#user' do
    it 'gets a specific user' do
      user = t.user(119_240)
      expect(user).to be_an_instance_of Trav3::Success
    end

    it 'sync a user account with Github' do
      user = t.user(114_816, :sync)
      expect(user).to be_an_instance_of Trav3::Success
    end

    it 'gets the current user' do
      user = t.user
      expect(user).to be_an_instance_of Trav3::Success
    end
  end
end
