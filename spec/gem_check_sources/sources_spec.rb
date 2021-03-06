require File.dirname(__FILE__) + '/../spec_helper'

describe Gem::Sources do
  include Gem::Sources
  
  describe "#currently_loaded_sources" do
    it "should load all of the sources from 'gem sources'" do
      currently_loaded_sources.should == `gem sources`.split("\n").select { |s| /http/ =~ s }
    end
  end
    
  describe Gem::Sources::List do
    before(:each) do
      @sources = {
        :active => ['http://active.example.com'],
        :inactive => ['http://inactive.example.com']
      }
      @list = Gem::Sources::List.new(@sources)
    end
    
    describe "##load_file" do
      it "should load the given YAML" do
        @test_sources_file = Dir.tmpdir + "/test_gem_sources.yml"        
        File.open(@test_sources_file, 'w+') {|out| YAML.dump(@sources, out) }
        
        file_list = Gem::Sources::List.load_file(@test_sources_file)
        file_list.active.should == @list.active
        file_list.inactive.should == @list.inactive
        
        File.delete @test_sources_file
      end
    end
    
    describe "#all" do
      it "should include both active and inactive sources" do
        @list.all.sort.should == ['http://active.example.com', 'http://inactive.example.com'].sort
      end
    end
    
    describe "#to_h" do
      it "should serialize to a hash" do
        @list.to_h.should == @sources
      end
    end
    
    describe "#dump" do
      it "should dump the hash representation to the given file" do
        io = mock('FILE')
        File.stub(:open).and_yield(io)
        YAML.should_receive(:dump).once.with(@list.to_h, io)
        @list.dump('file')
      end
    end
    
    describe "#verify" do
      it "should check all sources" do
        @list.should_receive(:source_available?).exactly(@list.size).times.and_return(true)
        @list.verify
      end
      
      it "should sort the sources into active and inactive" do
        @list.stub!(:source_available?).and_return(true, false)
        @list.verify
        @list.active.should_not be_empty
        @list.inactive.should_not be_empty
      end
    end
    
    describe "#add" do
      it "should check if the source is available it to the appropriate list" do
        @list.stub!(:source_available?).and_return(false)
        @list.add('http://yas.example.com')
        @list.inactive.should include('http://yas.example.com')
        @list.active.should_not include('http://yas.example.com')
      end
    end
    
    describe "#remove" do
      it "should remove the source from all lists" do
        @list.remove('http://active.example.com')
        @list.all.should_not include('http://active.example.com')
      end
    end
    
    describe "#sync" do
      before(:each) do
        @list.stub!(:currently_loaded_sources).and_return(['http://inactive.example.com'])
      end
      
      it "should add all active sources that are not currently loaded" do
        @list.should_receive(:add_system_source).once.with('http://active.example.com')
        @list.stub!(:remove_system_source)
        @list.sync
      end
      
      it "should remove any inactive sources that are currently loaded" do
        @list.should_receive(:remove_system_source).once.with('http://inactive.example.com')
        @list.stub!(:add_system_source)
        @list.sync
      end
    end
  end
end