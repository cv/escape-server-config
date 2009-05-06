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
        @selenium_driver = Selenium::Client::Driver.new("localhost", 4444, "*firefox", "http://localhost:7000", 30)
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
        page.wait_for_element('//input[@id="new_env_name"]')
        # Type "zoo" in the then object called 'new_env_name'
        page.type('//input[@id="new_env_name"]', "zoo")
        # Simulate pressing enter in the text box
        page.key_press('//input[@id="new_env_name"]', '13')
        page.wait_for_element('//span[@class="envName" and text()="zoo"]')
    end

    it "should be able to add a new app to the zoo environment" do
        page.open("/")
        # Click on the "zoo" environment span
        page.wait_for_element('//span[@class="envName" and text()="zoo"]')
        page.click('//span[@class="envName" and text()="zoo"]')
        # Wait for apps to be loaded for this env
        page.wait_for_element('//li[@id="zoo"]//ul[@class="application_list"]//form[@class="new_app_form"]//input[@id="new_app_name"]')
        # Type in the app name "cage" and add it to the zoo env
        page.click('//li[@id="zoo"]//ul[@class="application_list"]//form[@class="new_app_form"]//input[@id="new_app_name"]')
        page.type('//li[@id="zoo"]//ul[@class="application_list"]//form[@class="new_app_form"]//input[@id="new_app_name"]', "cage")
        page.key_press('//li[@id="zoo"]//ul[@class="application_list"]//form[@class="new_app_form"]//input[@id="new_app_name"]', '13')
        # Check that the app cage now appears under zoo
        page.wait_for_element('//li[@class="environment" and @id="zoo"]//ul[@class="application_list"]//li[@class="application" and @id="cage"]')
        # Check that the app cage now appears under default
        page.click('//span[@class="envName" and text()="default"]')
        page.wait_for_element('//li[@id="default"]//ul[@class="application_list"]//form[@class="new_app_form"]//input[@id="new_app_name"]')
        page.is_element_present('//li[@id="default"]//ul[@class="application_list"]//li[@class="application" and @id="cage"]').should == true
    end

    it "should be able to add a key to the new app in default" do
        page.open("/")
        # Click on default env
        page.wait_for_element('//span[@class="envName" and text()="default"]')
        page.click('//span[@class="envName" and text()="default"]')
        # Wait for apps to load
        page.wait_for_element('//li[@id="default"]//ul[@class="application_list"]//form[@class="new_app_form"]//input[@id="new_app_name"]')
        # Click on cage app
        page.click('//span[@class="appName" and text()="cage"]')
        # Wait for key/value table to load
        page.wait_for_element('//table[@id="key_value_table"]')
        # Click in add key box
        page.click('//input[@id="new_key_name"]')
        # Add key default.key
        page.type('//input[@id="new_key_name"]', "default.key")
        page.key_press('//input[@id="new_key_name"]', '13')
        page.wait_for_element('//table[@id="key_value_table"]//tbody//tr//td[@id="default.key"]')
        # Add default value to the key
        page.mouse_down('//table[@id="key_value_table"]//tbody//tr//td[@id="default.key"]')
        page.mouse_up('//table[@id="key_value_table"]//tbody//tr//td[@id="default.key"]')
        page.type('//input[@name="td_edit"]', "rubber")
        page.key_press('//input[@name="td_edit"]', '13')
        # Check that we see the default value in default
        page.wait_for_element('//table[@id="key_value_table"]//tbody//tr//td[@id="default.key"]')
        # Check that we see the default value in zoo
        page.get_text('//table[@id="key_value_table"]//tbody//tr//td[@id="default.key"]').should == "rubber"
    end
    
    it "should get error when adding a key that exists" do
        page.open("/")
        # Click on default env
        page.wait_for_element('//span[@class="envName" and text()="default"]')
        page.click('//span[@class="envName" and text()="default"]')
        # Wait for apps to load
        page.wait_for_element('//li[@id="default"]//ul[@class="application_list"]//form[@class="new_app_form"]//input[@id="new_app_name"]')
        # Click on cage app
        page.click('//span[@class="appName" and text()="cage"]')
        # Wait for key/value table to load
        page.wait_for_element('//table[@id="key_value_table"]')
        # Click in add key box
        page.click('//input[@id="new_key_name"]')
        # Add key default.key
        page.type('//input[@id="new_key_name"]', "default.key")
        page.key_press('//input[@id="new_key_name"]', '13')
        page.alert().should == 'default.key exists!'
    end

    it "should have the default value in the zoo env" do
        page.open("/")
        # Click on zoo env
        page.wait_for_element('//span[@class="envName" and text()="zoo"]')
        page.click('//span[@class="envName" and text()="zoo"]')
        # Wait for apps to load
        page.wait_for_element('//li[@id="zoo"]//ul[@class="application_list"]//form[@class="new_app_form"]//input[@id="new_app_name"]')
        # Click on cage app
        page.click('//li[@id="zoo"]//span[@class="appName" and text()="cage"]')
        # Wait for key/value table to load
        page.wait_for_element('//table[@id="key_value_table"]')
        # Check that we see the default value in default
        page.wait_for_element('//table[@id="key_value_table"]//tbody//tr//td[@id="default.key"]')
        # Check that we see the default value in zoo
        page.get_text('//table[@id="key_value_table"]//tbody//tr//td[@id="default.key"]').should == "rubber"
    end

    it "should be able to override env specific values" do
        page.open("/")
        # Click on zoo env
        page.wait_for_element('//span[@class="envName" and text()="zoo"]')
        page.click('//span[@class="envName" and text()="zoo"]')
        # Wait for apps to load
        page.wait_for_element('//li[@id="zoo"]//ul[@class="application_list"]//form[@class="new_app_form"]//input[@id="new_app_name"]')
        # Click on cage app in zoo
        page.click('//li[@id="zoo"]//span[@class="appName" and text()="cage"]')
        # Wait for key/value table to load
        page.wait_for_element('//table[@id="key_value_table"]//tbody//tr//td[@id="default.key"]')
        # Add default value to the key
        page.mouse_down('//table[@id="key_value_table"]//tbody//tr//td[@id="default.key"]')
        page.mouse_up('//table[@id="key_value_table"]//tbody//tr//td[@id="default.key"]')
        page.type('//input[@name="td_edit"]', "steel")
        page.key_press('//input[@name="td_edit"]', '13')
        # Check that we see the new value in zoo
        page.wait_for_element('//table[@id="key_value_table"]//tbody//tr//td[@id="default.key"]')
        page.get_text('//table[@id="key_value_table"]//tbody//tr//td[@id="default.key"]').should == "steel"
        # Check that we see the default value in default
        page.click('//span[@class="envName" and text()="default"]')
        # Wait for apps to load
        page.wait_for_element('//li[@id="default"]//ul[@class="application_list"]//form[@class="new_app_form"]//input[@id="new_app_name"]')
        # Click on cage app in default
        page.click('//li[@id="default"]//span[@class="appName" and text()="cage"]')
        # Check that we see the default value in default
        page.wait_for_element('//table[@id="key_value_table"]//tbody//tr//td[@id="default.key"]')
        page.get_text('//table[@id="key_value_table"]//tbody//tr//td[@id="default.key"]').should == "rubber"
    end
end
