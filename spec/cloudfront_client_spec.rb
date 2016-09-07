require 'rspec'
require 'configure-s3-website'
require "rexml/document"
require "rexml/xpath"

describe ConfigureS3Website::CloudFrontClient do
  context '#distribution_config_xml' do
    describe 'letting the user to override the default values' do
      let(:config_source) {
        mock = double('config_source')
        allow(mock).to receive(:s3_bucket_name).and_return('test-bucket')
        allow(mock).to receive(:s3_endpoint).and_return(nil)
        mock
      }

      let(:custom_settings) {
        { 'default_cache_behavior' => { 'min_TTL' => '987' } }
      }

      let(:distribution_config_xml) {
        REXML::Document.new(
          ConfigureS3Website::CloudFrontClient.send(
            :distribution_config_xml,
            config_source,
            custom_settings
          )
        )
      }

      it 'allows the user to override default CloudFront settings' do
        expect(REXML::XPath.first(
          distribution_config_xml,
          '/DistributionConfig/DefaultCacheBehavior/MinTTL'
        ).get_text.to_s).to eq('987')
      end

      it 'retains the default values that are not overriden' do
        expect(REXML::XPath.first(
          distribution_config_xml,
          '/DistributionConfig/DefaultCacheBehavior/ViewerProtocolPolicy'
        ).get_text.to_s).to eq('allow-all')
      end
    end

    [
      { :region => 'us-east-1', :website_endpoint => 's3-website-us-east-1.amazonaws.com' },
      { :region => 'us-west-1', :website_endpoint => 's3-website-us-west-1.amazonaws.com' },
      { :region => 'us-west-2', :website_endpoint => 's3-website-us-west-2.amazonaws.com' },
      { :region => 'ap-south-1', :website_endpoint => 's3-website.ap-south-1.amazonaws.com' },
      { :region => 'ap-northeast-2', :website_endpoint => 's3-website.ap-northeast-2.amazonaws.com' },
      { :region => 'ap-southeast-1', :website_endpoint => 's3-website-ap-southeast-1.amazonaws.com' },
      { :region => 'ap-southeast-2', :website_endpoint => 's3-website-ap-southeast-2.amazonaws.com' },
      { :region => 'ap-northeast-1', :website_endpoint => 's3-website-ap-northeast-1.amazonaws.com' },
      { :region => 'eu-central-1', :website_endpoint => 's3-website.eu-central-1.amazonaws.com' },
      { :region => 'eu-west-1', :website_endpoint => 's3-website-eu-west-1.amazonaws.com' },
      { :region => 'sa-east-1', :website_endpoint => 's3-website-sa-east-1.amazonaws.com' },
    ].each { |conf|
      region = conf[:region]
      website_endpoint = conf[:website_endpoint]
      describe "inferring //Origins/Items/Origin/DomainName (#{region})" do
        let(:config_source) {
          mock = double('config_source')
          allow(mock).to receive(:s3_bucket_name).and_return('test-bucket')
          allow(mock).to receive(:s3_endpoint).and_return(region)
          mock
        }

        let(:distribution_config_xml) {
          REXML::Document.new(
            ConfigureS3Website::CloudFrontClient.send(
              :distribution_config_xml,
              config_source,
              custom_distribution_config = {}
            )
          )
        }

        it "honors the endpoint of the S3 website (#{region})" do
          expect(REXML::XPath.first(
            distribution_config_xml,
            '/DistributionConfig/Origins/Items/Origin/DomainName'
          ).get_text.to_s).to eq("test-bucket.#{website_endpoint}")
        end
      end
    }

  end
end
