require 'spec_helper'

describe MustBe do
  include MustBeExampleHelper
  
  describe Proxy do
    subject { Proxy.new(:moxie) }
    
    context "when initialized with method other than :must or :must_not" do
      it "should raise ArgumentError" do
        expect do
          Proxy.new(:moxie, :must_could)
        end.should raise_error(ArgumentError,
          "assertion (:must_could) must be :must or :must_not")
      end
    end
    
    describe "it should not forward" do
      example "#__id__" do
        subject.__id__.should_not == :moxie.__id__
      end
      
      example "#object_id" do
        subject.object_id.should_not == :moxie.object_id
      end
    end
  end
  
  module ItShouldNotifyExpectations
    def it_should_notify(message, &implementation)
      example "#{message} should notify" do
        instance_eval(&implementation)
        should notify(message)
      end
    end
  
    def it_should_not_notify(message, &implementation)
      example "#{message} should not notify" do
        instance_eval(&implementation)
        should_not notify
      end
    end
  end
  
  describe '#must' do
    extend ItShouldNotifyExpectations
    
    context "when called with a block" do
      it "should return the receiver" do
        0xdad.must{}.object_id.should == 0xdad.object_id
      end
      
      it "should notify if block returns false" do
        :helm.must{|receiver| receiver == :harm }.should == :helm
        should notify(":helm.must {}")
      end
      
      it "should notify with message if provided" do
        :ice.must("ice must be icy") do |receiver|
          receiver == :icy
        end.should == :ice
        should notify("ice must be icy")
      end
      
      it "should not notify if block returns true" do
        :jinn.must{|receiver| receiver == :jinn }.should == :jinn
        should_not notify
      end
      
      it "should allow nested #must_notify" do
        :keys.must("electrify kites") do |receiver, message|
          must_notify("#{receiver} must #{message}")
          true
        end.should == :keys
        should notify("keys must electrify kites")
      end
    end
    
    context "when used to proxy" do
      subject { 230579.must }
      
      it_should_notify("230579.must.==(70581)") do
        subject == 70581
      end
        
      it_should_not_notify("230579.must.>(411)") do
        subject > 411
      end
      
      it_should_not_notify("230579.must.odd?") do
        subject.odd?
      end
      
      it_should_notify("230579.must.between?(-4, 4)") do
        subject.between?(-4, 4)
      end
      
      it_should_notify("230579.must.respond_to?(:finite?)") do
        subject.respond_to? :finite?
      end
      
      it_should_not_notify("230579.must.instance_of?(Fixnum)") do
        subject.instance_of? Fixnum
      end
      
      it_should_notify("230579.must.instance_of?(Integer)") do
        subject.instance_of? Integer
      end
      
      it "should have a different #object_id" do
        subject.should == 230579
        subject.object_id.should_not == 230579.object_id
      end
      
      context "after MustBe.disable" do
        before_disable_after_enable
        
        it "should have the same #object_id" do
          subject.object_id.should == 230579.object_id
        end
      end
    end
  end
  
  describe '#must_not' do
    extend ItShouldNotifyExpectations
        
    context "when called with a block" do
      it "should return the receiver" do
        0xdad.must_not{}.should == 0xdad
      end
      
      it "should notify if block returns true" do
        :helm.must_not{|receiver| receiver == :helm }.should == :helm
        should notify(":helm.must_not {}")
      end
      
      it "should notify with message if provided" do
        :ice.must_not("ice must not be ice") do |receiver|
          receiver == :ice
        end.should == :ice
        should notify("ice must not be ice")
      end
      
      it "should not notify if block returns false" do
        :jinn.must_not{|receiver| receiver == :gem }.should == :jinn
        should_not notify
      end
      
      it "should allow nested #must_notify" do
        :keys.must_not("electrify kites") do |receiver, message|
          must_notify("#{receiver} must not #{message}")
          false
        end.should == :keys
        should notify("keys must not electrify kites")
      end
    end
    
    context "when used to proxy" do
      subject { 230579.must_not }
      
      it_should_not_notify("230579.must_not.==(70581)") do
        subject == 70581
      end
        
      it_should_notify("230579.must_not.>(411)") do
        subject > 411
      end
      
      it_should_notify("230579.must_not.odd?") do
        subject.odd?
      end
      
      it_should_not_notify("230579.must_not.between?(-4, 4)") do
        subject.between?(-4, 4)
      end
      
      it_should_not_notify(
          "230579.must_not.respond_to?(:finite?)") do
        subject.respond_to? :finite?
      end
      
      it_should_notify("230579.must_not.instance_of?(Fixnum)") do
        subject.instance_of? Fixnum
      end
      
      it_should_not_notify(
          "230579.must_not.instance_of?(Integer)") do
        subject.instance_of? Integer
      end
    end
  end
  
end