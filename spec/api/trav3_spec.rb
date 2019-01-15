require 'spec_helper'

RSpec.describe Trav3::Travis, :vcr do
  let(:t) { build :travis }

  describe '#new' do
    it 'returns a valid instance with good repo name' do
      expect(t).to be_an_instance_of Trav3::Travis
      expect(t.send(:repository_name)).to eq 'danielpclark%2Ftrav3'
    end

    let(:travis) { Trav3::Travis.new('asdf-asdf') }
    it 'raises Trav3::InvalidRepository when invalid' do
      expect { travis }.to raise_error(Trav3::InvalidRepository, /invlaid/)
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

  describe '#build' do
    it 'gets build info' do
      build = t.build(351_778_872)
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
  end

  describe '#build_jobs' do
    it 'gets build job details for build' do
      build_jobs = t.build_jobs(351_778_872)
      expect(build_jobs).to be_an_instance_of Trav3::Success
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
      # TODO: A job needs to be running for this to work
      job = t.job(351_778_875, :cancel)
      expect(job).to be_an_instance_of Trav3::Success
    end

    it 'fails to use debug mode on the .org of Travis CI' do
      job = t.job(351_778_875, :debug)
      expect(job).to be_an_instance_of Trav3::RequestError
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

    it 'raises an unimplemented error when :delete is used' do
      expect { t.log(351_778_875, :delete) }.to raise_error(Trav3::Unimplemented, /not implemented/)
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
      organizations = t.organizations
      expect(organizations).to be_an_instance_of Trav3::Success
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

    it "method not allowed for syncing a user's account with Github" do
      user = t.user(114_816, :sync)
      expect(user).to be_an_instance_of Trav3::RequestError
      expect(user['error_message']).to eq 'method not allowed'
    end

    it 'gets the current user' do
      user = t.user
      expect(user).to be_an_instance_of Trav3::Success
    end
  end
end
