require 'rubygems'
require 'rake'
require 'spec/rake/spectask'

Spec::Rake::SpecTask.new('spec') do |t|
  t.spec_opts = ['--format', 'specdoc', '--colour']
  t.spec_files = Dir['*/spec/**/*_spec.rb'].sort
end

Spec::Rake::SpecTask.new('rcov') do |t|
  t.spec_opts = ['--colour']
  t.spec_files = Dir['*/spec/**/*_spec.rb'].sort
  t.rcov = true
  t.rcov_opts = ['--text-summary --exclude evolution/lib/d2na-evolution.rb']
end
