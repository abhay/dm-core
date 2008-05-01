require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

begin
  gem 'do_sqlite3', '=0.9.0'
  require 'do_sqlite3'

  DataMapper.setup(:sqlite3, "sqlite3://#{INTEGRATION_DB_PATH}") unless DataMapper::Repository.adapters[:sqlite3]

  describe "DataMapper::Resource" do
    describe "inheritance" do
      before(:all) do
        class Male
          include DataMapper::Resource
          property :id, Fixnum, :serial => true
          property :name, String
          property :iq, Fixnum, :default => 100
          property :type, Class, :default => lambda { |r,p| p.model }
        end
        
        class Bully < Male
          # property :brutal, Boolean, :default => true 
          # Automigrate should add fields for all subclasses of an STI-model, but currently it does not.
        end
        
        class Geek < Male
          property :awkward, Boolean, :default => true
        end
        
        Geek.auto_migrate!(:sqlite3)
        
        repository(:sqlite3) do
          Male.create!(:name => 'John Dorian')
          Bully.create!(:name => 'Bob')
          Geek.create!(:name => 'Steve', :awkward => false, :iq => 132)
          Geek.create!(:name => 'Bill', :iq => 150)
          Bully.create!(:name => 'Johnson')
        end
      end
      
      it "should select appropriate types" do
        repository(:sqlite3) do
          males = Male.all
          males.should have(5).entries
          
          males.each do |male|
            male.class.name.should == male.type.name
          end
          
          Male.first(:name => 'Steve').should be_a_kind_of(Geek)
          Bully.first(:name => 'Bob').should be_a_kind_of(Bully)
          Geek.first(:name => 'Steve').should be_a_kind_of(Geek)
          Geek.first(:name => 'Bill').should be_a_kind_of(Geek)
          Bully.first(:name => 'Johnson').should be_a_kind_of(Bully)
          Male.first(:name => 'John Dorian').should be_a_kind_of(Male) 
        end
      end
      
      it "should not select parent type" do
        pending("Bug...")
        repository(:sqlite3) do
          Male.first(:name => 'John Dorian').should be_a_kind_of(Male)
          Geek.first(:name => 'John Dorian').should be_nil
          Geek.first.iq.should > Bully.first.iq # now its matching Male#1 against Male#1        
        end
      end
    end
  end
rescue LoadError
  warn "integration/repository_spec not run! Could not load do_sqlite3."
end