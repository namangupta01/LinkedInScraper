require 'selenium-webdriver'
require 'byebug'

options = Selenium::WebDriver::Chrome::Options.new(args: ['headless', 'no-sandbox', 'disable-dev-shm-usage'])
Selenium::WebDriver::Chrome::Service.driver_path="/usr/bin/chromedriver"
driver = Selenium::WebDriver.for(:chrome, options: options)
driver.manage.timeouts.implicit_wait = 10
driver.get('https://www.linkedin.com/login?fromSignIn=true&trk=guest_homepage-basic_nav-header-signin/')
element = driver.find_element(name: 'session_key')
element.send_keys(ENV['EMAIL'])
element = driver.find_element(name: 'session_password')
element.send_keys(ENV['PASSWORD'])
element.submit
sleep(2)

# Get target profile
profiles = [
    'https://www.linkedin.com/in/namangupta01/'
]

profiles.each do |profile|
  driver.get(profile)
  sleep(2)
  driver.execute_script("window.scrollTo(0, document.body.scrollHeight/2)")
  sleep(1)
  experience_section =  driver.find_element(:id, 'experience-section')
  sleep(1)

  see_more_buttons = experience_section.find_elements(:class, 'pv-profile-section__see-more-inline')
  see_more_buttons.each do |see_more_button|
    driver.action.move_to(see_more_button).perform
    see_more_button.click
    sleep(1)
  end
  sleep(1)

  linkedin_scraped_data = []
  employment_types = ["Full-time", "Part-time", "Self-employed", "Freelance", "Internship", "Trainee"]
  puts employment_types
  experiences = driver.find_elements(:class, 'pv-position-entity')
  presence=false
  for experience in experiences
    scraped_experience = experience.text.strip
    if scraped_experience.include? "Total Duration"
      # Handles cases with more than one designation in a company
      company_name = scraped_experience.split("Company Name\n").last.split("\n").first
      employment_types.each do |employment_type|
        if company_name.include? employment_type
          company_name = company_name.split(" #{employment_type}").first
          break
        end
      end
      multi_designation_experience = scraped_experience
      multi_designation_experience = multi_designation_experience.split("Title\n")
      multi_designation_experience.drop(1).each do |scraped_designation|
        designation = scraped_designation.split("\nDates Employed").first.split("\n").first
        duration = scraped_designation.split("Employment Duration\n").last.split("\n").first
        if scraped_designation.include? "Location\n"
          location = scraped_designation.split("Location\n").last.split("\n").first
        else
          location = ""
        end
        linkedin_scraped_data << {"company_name": company_name, "designation": designation, "location": "", "duration": duration}
      end
    else
      company_name = scraped_experience.split("Company Name\n").last.split("\nDates Employed").first
      employment_types.each do |employment_type|
        if company_name.include? employment_type
          company_name = company_name.split(" #{employment_type}").first
          break
        end
      end
      designation = scraped_experience.split("\nCompany Name").first
      if scraped_experience.include? "Location\n"
        location = scraped_experience.split("Location\n").last.split("\n").first
      else
        location = ""
      end
      duration = scraped_experience.split("Dates Employed\n").last.split("\nEmployment Duration").first
      linkedin_scraped_data << {"company_name": company_name, "designation": designation, "location": location, "duration": duration, "presence": presence}
    end
  end
  puts linkedin_scraped_data
end
driver.quit
