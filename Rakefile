# encoding: utf-8
require 'rake'
require 'rake/rdoctask'
gem 'rspec'
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

Rake::RDocTask.new do |rdoc|
  rdoc.main = 'README.rdoc'
  rdoc.rdoc_files.include('**/*.rdoc', '*/lib/**/*.rb')
  rdoc.title = 'D2NA'
  rdoc.rdoc_dir = 'doc'
  rdoc.options << '--charset utf-8' << '--all' << '--inline-source'
end
