require File.join(File.dirname(__FILE__), "spec_helper")

describe Sequel::Model, "#sti_key" do
  before do
    class ::StiTest < Sequel::Model
      def kind=(x); self[:kind] = x; end 
      def refresh; end 
      plugin :single_table_inheritance, :kind
    end 
    class ::StiTestSub1 < StiTest
    end 
    class ::StiTestSub2 < StiTest
    end 
    @ds = StiTest.dataset
    MODEL_DB.reset
  end 
  
  it "should return rows with the correct class based on the polymorphic_key value" do
    def @ds.fetch_rows(sql)
      yield({:kind=>'StiTest'})
      yield({:kind=>'StiTestSub1'})
      yield({:kind=>'StiTestSub2'})
    end 
    StiTest.all.collect{|x| x.class}.should == [StiTest, StiTestSub1, StiTestSub2]
  end 

  it "should fallback to the main class if polymophic_key value is NULL" do
    def @ds.fetch_rows(sql)
      yield({:kind=>nil})
    end 
    StiTest.all.collect{|x| x.class}.should == [StiTest]
  end 
  
  it "should fallback to the main class if the given class does not exist" do
    def @ds.fetch_rows(sql)
      yield({:kind=>'StiTestSub3'})
    end
    StiTest.all.collect{|x| x.class}.should == [StiTest]
  end

  it "should add a before_create hook that sets the model class name for the key" do
    StiTest.new.save
    StiTestSub1.new.save
    StiTestSub2.new.save
    MODEL_DB.sqls.should == ["INSERT INTO sti_tests (kind) VALUES ('StiTest')", "INSERT INTO sti_tests (kind) VALUES ('StiTestSub1')", "INSERT INTO sti_tests (kind) VALUES ('StiTestSub2')"]
  end

  it "should add a filter to model datasets inside subclasses hook to only retreive objects with the matching key" do
    StiTest.dataset.sql.should == "SELECT * FROM sti_tests"
    StiTestSub1.dataset.sql.should == "SELECT * FROM sti_tests WHERE (kind = 'StiTestSub1')"
    StiTestSub2.dataset.sql.should == "SELECT * FROM sti_tests WHERE (kind = 'StiTestSub2')"
  end
end
