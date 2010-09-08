require 'spec_helper'

describe MustBe do
  include MustBeExampleHelper
  
  describe Proxy do
    subject { Proxy.new(:moxie) }
    
    context "when initialized with invalid method" do
      it "should raise ArgumentError" do
        expect do
          Proxy.new(:moxie, :must_could)
        end.should raise_error(ArgumentError,
          "assertion (:must_could) must be :must or :must_not")
      end
    end
    
    context "when it should not forward" do
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
      it "`#{message}' should notify" do
        instance_eval &implementation
        should notify(message)
      end
    end
  
    def it_should_not_notify(message, &implementation)
      it "`#{message}' should not notify" do
        instance_eval &implementation
        should_not notify
      end
    end
  end
  
  describe "#must" do
    extend ItShouldNotifyExpectations
    
    context "when called with a block" do
      it "should return the receiver" do
        0xdad.must{}.should == 0xdad
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
      subject { 0xabaca_facade.must }
      
      it_should_notify("#{0xabaca_facade}.must.==(#{0xdefaced})") do
        subject == 0xdefaced
      end
        
      it_should_not_notify("#{0xabaca_facade}.must.>(#{0xfaded})") do
        subject > 0xfaded
      end
      
      it_should_not_notify("#{0xabaca_facade}.must.even?") do
        subject.even?
      end
      
      it_should_notify("#{0xabaca_facade}.must.between?(-4, 4)") do
        subject.between?(-4, 4)
      end
      
      it_should_notify("#{0xabaca_facade}.must.respond_to?(:finite?)") do
        subject.respond_to? :finite?
      end
      
      it_should_not_notify("#{0xabaca_facade}.must.instance_of?(Fixnum)") do
        subject.instance_of? Fixnum
      end
      
      it_should_notify("#{0xabaca_facade}.must.instance_of?(Integer)") do
        subject.instance_of? Integer
      end
      
      it "should have a different #object_id" do
        subject.should == 0xabaca_facade
        subject.object_id.should_not == 0xabaca_facade.object_id
      end
      
      context "after MustBe.disable" do
        before_disable_after_enable
        
        it "should have the same #object_id" do
          subject.object_id.should == 0xabaca_facade.object_id
        end
      end
    end
  end
  
  describe "#must_not" do
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
      subject { 0xabaca_facade.must_not }
      
      it_should_not_notify("#{0xabaca_facade}.must_not.==(#{0xdefaced})") do
        subject == 0xdefaced
      end
        
      it_should_notify("#{0xabaca_facade}.must_not.>(#{0xfaded})") do
        subject > 0xfaded
      end
      
      it_should_notify("#{0xabaca_facade}.must_not.even?") do
        subject.even?
      end
      
      it_should_not_notify("#{0xabaca_facade}.must_not.between?(-4, 4)") do
        subject.between?(-4, 4)
      end
      
      it_should_not_notify(
          "#{0xabaca_facade}.must_not.respond_to?(:finite?)") do
        subject.respond_to? :finite?
      end
      
      it_should_notify("#{0xabaca_facade}.must_not.instance_of?(Fixnum)") do
        subject.instance_of? Fixnum
      end
      
      it_should_not_notify(
          "#{0xabaca_facade}.must_not.instance_of?(Integer)") do
        subject.instance_of? Integer
      end
    end
  end
  
end