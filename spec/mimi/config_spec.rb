require 'spec_helper'

describe Mimi::Config do
  let(:manifest_filename_1) { fixture_path('manifest.1.yml') }
  let(:manifest_hash_1) do
    {
      min1: {
        desc: '',
        type: :string,
        hidden: false,
        const: false
      },
      opt1: {
        desc: 'This is an optional configurable parameter',
        default: 'opt1.default',
        type: :string,
        hidden: false,
        const: false
      },
      req1: {
        desc: 'This is a required configurable parameter',
        type: :string,
        hidden: false,
        const: false
      },
      opt2: {
        desc: '',
        default: nil,
        type: :integer,
        hidden: false,
        const: false
      },
      const1: {
        desc: 'This is a constant parameter',
        type: :string,
        default: 'const1.default',
        hidden: false,
        const: true
      }
    }
  end
  let(:env_vars_1) do
    {
      min1: 'min1.value',
      opt1: 'opt1.value',
      req1: 'req1.value',
      opt2: '2',
      const1: 'const1.value',
      foobar: 'foobar.value',
    }
  end
  let(:config_1_hash) do
    {
      min1: 'min1.value',
      opt1: 'opt1.value',
      req1: 'req1.value',
      opt2: 2,
      const1: 'const1.default'
    }
  end
  let(:env_vars_1_req1_missing) do
    {
      min1: 'min1.value',
      opt1: 'opt1.value',

      opt2: '2',
      const1: 'const1.value',
      foobar: 'foobar.value',
    }
  end
  let(:env_vars_1_opt1_missing) do
    {
      min1: 'min1.value',

      req1: 'req1.value',
      opt2: '2',
      const1: 'const1.value',
      foobar: 'foobar.value',
    }
  end
  let(:env_vars_1_opt2_invalid) do
    {
      min1: 'min1.value',
      opt1: 'opt1.value',
      req1: 'req1.value',
      opt2: '2foobar',
      const1: 'const1.value',
      foobar: 'foobar.value',
    }
  end

  it 'has a version number' do
    expect(Mimi::Config::VERSION).not_to be nil
  end

  it 'is a Class' do
    expect(Mimi::Config).to be_a Class
  end

  context '.new' do
    subject do
      with_env_vars(env_vars_1) do
        Mimi::Config.new(manifest_filename_1)
      end
    end

    it 'creates a new Config object from a manifest file' do
      expect { subject }.to_not raise_error
      expect(subject).to be_a Mimi::Config
    end

    it 'exposes parsed manifest' do
      expect(subject).to respond_to(:manifest)
      expect { subject.manifest.to_h }.to_not raise_error
      expect(subject.manifest.to_h).to eq manifest_hash_1
    end

    it { is_expected.to respond_to(:min1) }
    it { is_expected.to respond_to(:opt1) }
    it { is_expected.to respond_to(:req1) }
    it { is_expected.to respond_to(:opt2) }
    it { is_expected.to respond_to(:const1) }
    it { is_expected.to respond_to(:[]) }
    it { is_expected.to respond_to(:include?) }
    it { is_expected.to respond_to(:to_h) }
    it { is_expected.to_not respond_to(:foobar) }

    it 'processes manifest and ENV values, sets configurable parameters' do
      expect { subject.min1 }.to_not raise_error
      expect(subject.min1).to eq 'min1.value'
      expect(subject.opt1).to eq 'opt1.value'
      expect(subject.req1).to eq 'req1.value'
      expect(subject.opt2).to eq 2
      expect(subject.const1).to eq 'const1.default'
    end

    it 'makes the parameters value available as Hash via #to_h' do
      expect { subject.to_h }.to_not raise_error
      expect(subject.to_h).to be_a Hash
      expect(subject.to_h).to eq config_1_hash
    end
  end # .new

  context '#[]' do
    let(:config) do
      with_env_vars(env_vars_1) do
        Mimi::Config.new(manifest_filename_1)
      end
    end
    subject { config }

    it 'provides accesss to parameter values' do
      expect { subject[:min1] }.to_not raise_error
      expect(subject[:min1]).to eq 'min1.value'
    end

    it 'does NOT allow accessing parameters as string keys' do
      expect { subject['min1'] }.to raise_error(ArgumentError)
    end

    it 'raises an error when accessing missing parameter' do
      expect { subject[:foobar] }.to raise_error(ArgumentError)
    end
  end # #[]

  context '.new() validation' do
    let(:config_req1_missing) do
      with_env_vars(env_vars_1_req1_missing) do
        Mimi::Config.new(manifest_filename_1)
      end
    end
    let(:config_opt1_missing) do
      with_env_vars(env_vars_1_opt1_missing) do
        Mimi::Config.new(manifest_filename_1)
      end
    end
    let(:config_opt2_invalid) do
      with_env_vars(env_vars_1_opt2_invalid) do
        Mimi::Config.new(manifest_filename_1)
      end
    end

    it 'does NOT raise error if an optional parameter is missing' do
      expect { config_opt1_missing }.to_not raise_error
    end

    it 'raises an error if a required parameter is missing' do
      expect { config_req1_missing }.to raise_error(ArgumentError)
    end

    it 'raises an error if a provided ENV value is invalid' do
      expect { config_opt2_invalid }.to raise_error(ArgumentError)
    end
  end # .new() validation
end
