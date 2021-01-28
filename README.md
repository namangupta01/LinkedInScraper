docker build -t linkedin-scraper .

docker run -e EMAIL='emailid' -e PASSWORD='password' -e -it linkedin-scraper ruby app.rb >> output.log
