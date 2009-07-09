#!/usr/bin/env ruby

$LOAD_PATH.push(File.expand_path(File.dirname(__FILE__)))
require 'init'

describe EnvironmentsController, 'Application bits' do
    behaves_like :rack_test, :db_helper

    before do
        reset_db
    end

    # App tests
    it 'should create an app on put /environments/default/appname' do
        got = put('/environments/default/appname')
        got.status.should == 201

        got = get('/environments/default')
        got.status.should == 200
        got.body.should.include "appname"
    end

    it 'should list apps in an environment' do
        got = put('/environments/default/appname')
        got.status.should == 201

        got = get('/environments/default')
        got.status.should == 200
        got.body.should.include "appname"
    end

    it 'should return 404 for non existing app' do
        got = get('/environments/default/badapp')
        got.status.should == 404
    end

    it 'should return 404 for apps that do exist by are not in specified environment' do
        got = put('/environments/default/appname')
        got.status.should == 201

        got = put('/environments/myenv')
        got.status.should == 201

        got = get('/environments/myenv/appname')
        got.status.should == 404
    end

    it 'should only list apps in the specified environment' do
        got = put('/environments/default/appname')
        got.status.should == 201

        got = put('/environments/myenv')
        got.status.should == 201

        got = put('/environments/myenv/myapp')
        got.status.should == 201

        got = get('/environments/myenv')
        got.status.should == 200
        got.body.should.not.include "appname"
        got.body.should.include "myapp"
    end

    it 'should always add new apps to the default environment' do
        got = put('/environments/default/appname')
        got.status.should == 201

        got = put('/environments/myenv')
        got.status.should == 201

        got = put('/environments/myenv/myapp')
        got.status.should == 201

        got = get('/environments/default')
        got.status.should == 200
        got.body.should.include "appname"
        got.body.should.include "myapp"
    end

    it 'should not allow apps to be created in non existing environments' do
        got = put('/environments/badenv/badapp')
        got.status.should == 404
    end

    it 'should only add apps to default environment once' do
        got = get('/environments/default')
        got.status.should == 200
        got.body.should == '[]'

        got = put('/environments/default/appname')
        got.status.should == 201

        got = get('/environments/default')
        got.status.should == 200
        got.body.should == '["appname"]'
        
        got = put('/environments/default/appname')
        got.status.should == 201

        got = get('/environments/default')
        got.status.should == 200
        got.body.should == '["appname"]'
    end

    it 'should only add apps to specified environments once' do
        got = put('/environments/myenv')
        got.status.should == 201

        got = put('/environments/myenv/appname')
        got.status.should == 201

        got = get('/environments/myenv')
        got.status.should == 200
        got.body.should == '["appname"]'
        
        got = put('/environments/myenv/appname')
        got.status.should == 201

        got = get('/environments/myenv')
        got.status.should == 200
        got.body.should == '["appname"]'
    end

    it 'should only accept \A[.a-zA-Z0-9_-]+\Z as environment name' do
        got = put('/environments/default/spaced%20out%20name')
        got.status.should == 403
        
        got = put('/environments/default/Legal-app_name')
        got.status.should == 201

        got = put('/environments/default/still.legal')
        got.status.should == 201
    end
        
    it 'should delete an existing application from an environment' do
        got = put('/environments/myenv')
        got.status.should == 201
        got = get('/environments/myenv')
        got.status.should == 200
        got.body.should == '[]'
      
        got = put('/environments/myenv/myapp')
        got.status.should == 201
        got = get('/environments/myenv')
        got.status.should == 200
        got.body.should == '["myapp"]'

        got = get('/environments/myenv/myapp')
        got.status.should == 200
        got.body.should == ""
      
        got = delete('/environments/myenv/myapp')
        got.status.should == 200

        got = get('/environments/default/myapp')
        got.status.should == 200   
        got.body.should == ""

        got = get('/environments/myenv/myapp')
        got.status.should == 404
    end
    
    it 'should not cascade delete an application from default' do
        got = put('/environments/myenv')
        got.status.should == 201
      
        got = put('/environments/myenv/myapp')
        got.status.should == 201
      
        got = get('/environments/myenv/myapp')
        got.status.should == 200

        got = delete('/environments/default/myapp')
        got.status.should == 412

        got = delete('/environments/myenv/myapp')
        got.status.should == 200
        
        got = delete('/environments/default/myapp')
        got.status.should == 200

        got = get('/environments/myenv/myapp')
        got.status.should == 404
        
        got = get('/environments/default/myapp')
        got.status.should == 404
    end

end
