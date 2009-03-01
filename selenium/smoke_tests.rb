#!/usr/bin/env ruby

require 'rubygems'
gem "rspec", "=1.1.12"
gem "selenium-client", "=1.2.10"
require "spec"
require "selenium/client"
require "selenium/rspec/spec_helper"

describe "ESCAPE Management Interface" do
    attr_reader :selenium_driver
    alias :page :selenium_driver

    before(:all) do
        @selenium_driver = Selenium::Client::Driver.new("localhost", 4444, "*firefox", "http://localhost:7000")
        selenium_driver.start_new_browser_session
        
    end

    after(:all) do
        @selenium_driver.close_current_browser_session
    end

    it "should find the default environment" do
        page.open("/")
        page.title.should == "Esc Serves Config"

        page.get_text("//ul[@class='environment_list']//li").should == "default"
    end

    it "should be able to add a new environment" do
        page.open("/")
        # Type "zoo" in the then object called 'new_env_name'
        page.type("new_env_name", "zoo")
        # Simulate pressing enter in the text box
        page.key_press("new_env_name", '13')
    end

    it "should be able to add a new app to the zoo environment" do
        page.open("/")
        # Click on the "zoo" environment span
        page.click("//span[@class='envName' and text()='zoo']")
        # Wait for apps to be loaded for this env
        page.wait_for(:element => "//form[@class='new_app_form']//input[@id='new_app_name']")
        # Type in the app name "cage" and add it to the zoo env
        page.click("//form[@class='new_app_form']//input[@id='new_app_name']")
        page.type("//form[@class='new_app_form']//input[@id='new_app_name']", "cage")
        page.key_press("//form[@class='new_app_form']//input[@id='new_app_name']", '13')
        # Check that the app cage now appears under zoo
        page.wait_for(:element => "//li[@class='environment' and @id='zoo']//ul[@class='application_list']//li[@class='application' and @id='cage']")
        # Check that the app cage now appears under default
    end
end
