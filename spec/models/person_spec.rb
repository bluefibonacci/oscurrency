require File.dirname(__FILE__) + '/../spec_helper'

describe Person do

  before(:each) do
    @person = people(:quentin)
  end

  describe "attributes" do
    it "should be valid" do
      create_person.should be_valid
    end
  
    it 'requires password' do
      u = create_person(:password => nil)
      u.errors.on(:password).should_not be_nil
    end

    it 'requires password confirmation' do
      u = create_person(:password_confirmation => nil)
      u.errors.on(:password_confirmation).should_not be_nil
    end

    it 'requires email' do
      u = create_person(:email => nil)
      u.errors.on(:email).should_not be_nil
    end
    
    it "should have associated photos" do
      @person.photos.should_not be_nil
    end
    
    it "should not currently have any photos" do
      @person.photos.should be_empty
    end
    
    it "should have an associated blog on creation" do
      person = create_person(:save => true)
      person.blog.should_not be_nil
    end
  end
  
  describe "photo methods" do
    
    before(:each) do
      @photo_1 = mock_photo(:primary => true)
      @photo_2 = mock_photo
      @photos = [@photo_1, @photo_2]
      @photos.stub!(:find_all_by_primary).and_return([@photo_1])
      @person.stub!(:photos).and_return(@photos)
    end
    
    it "should have a photo method" do
      @person.should respond_to(:photo)
    end
    
    it "should have a non-nil primary photo" do
      @person.photo.should_not be_nil
    end
    
    it "should have other photos" do
      @person.other_photos.should_not be_empty
    end
    
    it "should have the right other photos" do
      @person.other_photos.should == (@photos - [@person.photo])
    end
    
    it "should have a main photo" do
      @person.main_photo.should == @person.photo.public_filename
    end
    
    it "should have a thumbnail" do
      @person.thumbnail.should_not be_nil
    end

    it "should have an icon" do
      @person.icon.should_not be_nil
    end
    
    it "should have sorted photos" do
      @person.sorted_photos.should == [@photo_1, @photo_2]
    end
  end
  
  describe "message associations" do
    it "should have sent messages" do
      @person.sent_messages.should_not be_nil
    end
    
    it "should have received messages" do
      @person.received_messages.should_not be_nil
    end
  end
  
  describe "person contacts" do
    
    before(:each) do
      @contact = people(:aaron)
    end
    
    # TODO: make custom matchers to get
    # @contact.should have_requested_contacts
    it "should have requested contacts" do
      Connection.request(@person, @contact)
      @contact.requested_contacts.should_not be_empty
    end
    
    it "should have contacts" do
      Connection.request(@person, @contact)
      Connection.accept(@person, @contact)      
      @person.contacts.should == [@contact]
      @contact.contacts.should == [@person]
    end
  end
  
  describe "authentication" do
    it 'resets password' do
      @person.update_attributes(:password => 'newp',
                                :password_confirmation => 'newp')
      Person.authenticate('quentin@example.com', 'newp').should == @person
    end

    it 'authenticates person' do
      Person.authenticate('quentin@example.com', 'test').should == @person
    end
  
    it "should authenticate case-insensitively" do
      Person.authenticate('queNTin@eXample.com', 'test').should == @person    
    end

    it 'sets remember token' do
      @person.remember_me
      @person.remember_token.should_not be_nil
      @person.remember_token_expires_at.should_not be_nil
    end

    it 'unsets remember token' do
      @person.remember_me
      @person.remember_token.should_not be_nil
      @person.forget_me
      @person.remember_token.should be_nil
    end

    it 'remembers me for one week' do
      before = 1.week.from_now.utc
      @person.remember_me_for 1.week
      after = 1.week.from_now.utc
      @person.remember_token.should_not be_nil
      @person.remember_token_expires_at.should_not be_nil
      @person.remember_token_expires_at.between?(before, after).should be_true
    end

    it 'remembers me until one week' do
      time = 1.week.from_now.utc
      @person.remember_me_until time
      @person.remember_token.should_not be_nil
      @person.remember_token_expires_at.should_not be_nil
      @person.remember_token_expires_at.should == time
    end

    it 'remembers me default two weeks' do
      before = 2.years.from_now.utc
      @person.remember_me
      after = 2.years.from_now.utc
      @person.remember_token.should_not be_nil
      @person.remember_token_expires_at.should_not be_nil
      @person.remember_token_expires_at.between?(before, after).should be_true
    end    
  end

protected
  def create_person(options = {})
    record = Person.new({ :email => 'quire@example.com',
                          :password => 'quire',
                          :password_confirmation => 'quire',
                          :name => 'Quire',
                          :description => 'A new person' }.merge(options))
    record.valid?
    record.save! if options[:save]
    record
  end
end
