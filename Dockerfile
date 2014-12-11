FROM ubuntu:14.04
MAINTAINER elmundio87

ADD bot.rb	/root/bot.rb
ADD Gemfile /root/Gemfile

RUN apt-get update
RUN apt-get install ruby-full -y
RUN gem install bundle
RUN cd /root && bundle install

CMD ruby /root/bot.rb

EXPOSE 2000