# retrieved from http://docs.africastalking.com/smslibraries/ruby on 2018-04-11
# as suggested per http://docs.africastalking.com/sms/sending/ruby
require 'rubygems'
require 'net/http'
require 'uri'
require 'json'

class AfricasTalkingGatewayException < Exception
end

class SMSMessages
	attr_accessor :id, :text, :from, :to, :linkId, :date

	def initialize(id_, text_, from_, to_, linkId_, date_)
		@id     = id_
		@text   = text_
		@from   = from_
		@to     = to_
		@linkId = linkId_
		@date   = date_
	end
end

class StatusReport
	attr_accessor :number, :status, :cost, :messageId, :statusCode

	def initialize(number_, status_, cost_, messageId_, statusCode_)
		@number = number_
		@status = status_
		@cost   = cost_
		@messageId = messageId_
		@statusCode = statusCode_
	end
end

class PremiumSubscriptionNumbers
	attr_accessor :phoneNumber, :id

	def initialize(number_, id_)
		@phoneNumber = number_
		@id     = id_
	end
end

class AirtimeResult
	attr_accessor :amount, :phoneNumber, :requestId, :status, :errorMessage, :discount

	def initialize(status_, number_, amount_, requestId_, errorMessage_, discount_)
		@status       = status_
		@phoneNumber  = number_
		@amount       = amount_
		@requestId    = requestId_
		@errorMessage = errorMessage_
		@discount     = discount_
	end
end

class CallResponse
	attr_accessor :phoneNumber, :status

	def initialize(status_, number_)
		@status      = status_
		@phoneNumber = number_
	end
end

class QueuedCalls
	attr_accessor :numCalls, :phoneNumber, :queueName

	def initialize(number_, numCalls_, queueName_)
		@phoneNumber = number_
		@numCalls    = numCalls_
		@queueName   = queueName_
	end
end

class AfricasTalkingGateway

	HTTP_CREATED     = 201
	HTTP_OK          = 200

	#Set debug flag to to true to view response body
	DEBUG            = false


	def initialize(user_name,api_key, environment = nil)
		@user_name    = user_name
		@api_key      = api_key
		@environment  = environment

		@response_code = nil
	end

	def sendMessage(recipients_, message_, from_ = nil, bulkSMSMode_ = 1, enqueue_ = 0, keyword_ = nil, linkId_ = nil, retryDurationInHours_ = nil)
		post_body = {
						'username'    => @user_name,
						'message'     => message_,
						'to'          => recipients_,
						'bulkSMSMode' => bulkSMSMode_
					}
		if (from_ != nil)
			post_body['from'] = from_
		end

		if (enqueue_ > 0)
			post_body['enqueue'] = enqueue_
		end

		if (keyword_ != nil)
			post_body['keyword'] = keyword_
		end

		if (linkId_ != nil)
			post_body['linkId'] = linkId_
		end

		if (retryDurationInHours_ != nil)
			post_body['retryDurationInHours'] = retryDurationInHours_
		end

		response = executePost(getSmsUrl(), post_body)
		if @response_code == HTTP_CREATED
			messageData = JSON.parse(response,:quirks_mode=>true)["SMSMessageData"]
			recipients = messageData["Recipients"]

			if recipients.length > 0
				reports = recipients.collect { |entry|
					StatusReport.new entry["number"], entry["status"], entry["cost"], entry["messageId"], entry["statusCode"]
				}
				return reports
			end

			raise AfricasTalkingGatewayException, messageData["Message"]

		else
  			raise AfricasTalkingGatewayException, response
		end
	 end

	def fetchMessages(last_received_id_)
		url = getSmsUrl() + "?username=#{@user_name}&lastReceivedId=#{last_received_id_}"
		response = executePost(url)
		if @response_code == HTTP_OK
			messages = JSON.parse(response, :quirky_mode => true)["SMSMessageData"]["Messages"].collect { |msg|
				SMSMessage.new msg["id"], msg["text"], msg["from"] , msg["to"], msg["linkId"], msg["date"]
			}
			return messages
		else
			raise AfricasTalkingGatewayException, response
		end
	end

	def createSubcription(phone_number_, short_code_, keyword_)
		if(phone_number_.length == 0 || short_code.length == 0 || keyword_.length == 0)
			raise AfricasTalkingGatewayException, "Please supply phone number, short code and keyword"
		end

		post_body = {
						'username'    => @user_name,
						'phoneNumber' => phone_number_,
						'shortCode'   => short_code_,
						'keyword'     => keyword_
					}
		url      = getSmsSubscriptionUrl() + "/create"
		response = executePost(url, post_body)
		if(@response_code == HTTP_CREATED)
			return JSON.parse(response, :quirky_mode => true)
		else
			raise AfricasTalkingGatewayException, response
		end
	end

	def deleteSubcription(phone_number_, short_code_, keyword_)
		if(phone_number_.length == 0 || short_code.length == 0 || keyword_.length == 0)
			raise AfricasTalkingGatewayException, "Please supply phone number, short code and keyword"
		end

		post_body = {
						'username'    => @user_name,
						'phoneNumber' => phone_number_,
						'shortCode'   => short_code_,
						'keyword'     => keyword_
					}
		url = getSmsSubscriptionUrl() + "/delete"

		response = executePost(url, post_body)

		if(@response_code == HTTP_CREATED)
			return JSON.parse(response, :quirky_mode => true)
		else
			raise AfricasTalkingGatewayException, response
		end
	end

	def fetchPremiumSubscriptions(short_code_, keyword_, last_received_id_ = 0)
		if(short_code_.length == 0 || keyword_.length == 0)
			raise AfricasTalkingGatewayException, "Please supply the short code and keyword"
		end

		url = getSmsSubscriptionUrl() + "?username=#{@user_name}&shortCode=#{short_code_}&keyword=#{keyword_}&lastReceivedId=#{last_received_id_}"

		response = executePost(url)

		if(@response_code == HTTP_OK)
			subscriptions = JSON.parse(response)['responses'].collect{ |subscriber|
				PremiumSubscriptionNumbers.new subscriber['phoneNumber'], subscriber['id']
			}
			return subscriptions
		else
			raise AfricasTalkingGatewayException, response
		end
	end

	def call(from_, to_)
		post_body = {
						'username' => @user_name,
						'from'     => from_,
						'to'       => to_
					}
		response = executePost(getVoiceHost() + "/call", post_body)
		if(@response_code == HTTP_OK || @response_code == HTTP_CREATED)
			jObject = JSON.parse(response, :quirky_mode => true)

			if (jObject['errorMessage'] == "None")
				results = jObject['entries'].collect{|result|
					CallResponse.new result['status'], result['phoneNumber']
				}
				return results
			end

			raise AfricasTalkingGatewayException, jObject['errorMessage']
		end

		raise AfricasTalkingGatewayException, response
	end

	def getNumQueuedCalls(phone_number_, queue_name_ = nil)
		post_body = {
						'username'    => @user_name,
						'phoneNumbers' => phone_number_,
					}
		if (queue_name_ != nil)
			post_body['queueName'] = queue_name_
		end
		url = getVoiceHost() + "/queueStatus"
		response = executePost(url, post_body)

		jsObject = JSON.parse(response, :quirky_mode => true)

		if(@response_code == HTTP_OK || @response_code == HTTP_CREATED)
			if (jsObject['errorMessage'] == "None")
				results = jsObject['entries'].collect{|result|
					QueuedCalls.new result['phoneNumber'], result['numCalls'], result['queueName']
				}
				return results
			end

			raise AfricasTalkingGatewayException, jsObject['errorMessage']
		end

		raise AfricasTalkingGatewayException, response
	end

	def uploadMediaFile(url_string_)
		post_body = {
						'username' => @user_name,
						'url'      => url_string_
					}
		url      = getVoiceHost() + "/mediaUpload"
		response = executePost(url, post_body)

		jsObject = JSON.parse(response, :quirky_mode => true)

		raise AfricasTalkingGatewayException, jsObject['errorMessage'] if jsObject['errorMessage'] != "None"
	end

	def sendAirtime(recipients_)
		recipients = recipients_.to_json
		post_body = {
						'username'   => @user_name,
						'recipients' => recipients
					}
		url      = getAirtimeUrl() + "/send"
		response = executePost(url, post_body)
		if (@response_code == HTTP_CREATED)
			responses = JSON.parse(response, :quirky_mode =>true)['responses']
			if (responses.length > 0)
				results = responses.collect{ |result|
					AirtimeResult.new result['status'], result['phoneNumber'],result['amount'],result['requestId'], result['errorMessage'], result['discount']
				}
				return results
			else
				raise AfricasTalkingGatewayException, response['errorMessage']
			end
		else
			raise AfricasTalkingGatewayException, response
		end

	end

	 #Payment Methods
	def initiateMobilePaymentCheckout(productName_, phoneNumber_,  currencyCode_, amount_, metadata_ = {})
		parameters = {
			'username'     => @user_name,
			'productName'  => productName_,
			'phoneNumber'  => phoneNumber_,
			'currencyCode' => currencyCode_,
			'amount'       => amount_,
			'metadata'     => metadata_
		}

		url      = getMobilePaymentCheckoutUrl()
		response = sendJSONRequest(url, parameters)

		if (@response_code == HTTP_CREATED)
			resultObj = JSON.parse(response, :quirky_mode =>true)
			if (resultObj['status'] == 'PendingConfirmation')
				return resultObj['transactionId']
			end
			raise AfricasTalkingGatewayException, resultObj['description']
		end
		raise AfricasTalkingGatewayException, response
	end

	def mobilePaymentB2CRequest(productName_, recipients_)
		parameters = {
			'username'    => @user_name,
			'productName' => productName_,
			'recipients'  => recipients_
		}

		url      = getMobilePaymentB2CUrl()
		response = sendJSONRequest(url, parameters)

		if (@response_code == HTTP_CREATED)
			resultObj = JSON.parse(response, :quirky_mode =>true)
			if (resultObj['entries'].length > 0)
				return resultObj['entries']
			end
			raise AfricasTalkingGatewayException, resultObj['errorMessage']
		end
		raise AfricasTalkingGatewayException, response
	end

	def mobilePaymentB2BRequest(productName_, providerData_, currencyCode_, amount_, metadata_ = {})
		if (!providerData_.key?('provider'))
			raise AfricasTalkingGatewayException("Missing field provider")
		end

		if (!providerData_.key?('destinationChannel'))
			raise AfricasTalkingGatewayException("Missing field destinationChannel")
		end

		if (!providerData_.key?('destinationAccount'))
			raise AfricasTalkingGatewayException("Missing field destinationAccount")
		end

		if (!providerData_.key?('transferType'))
			raise AfricasTalkingGatewayException("Missing field transferType")
		end

		parameters = {
		              'username'           => @user_name,
		              'productName'        => productName_,
		              'provider'           => providerData_['provider'],
		              'destinationChannel' => providerData_['destinationChannel'],
		              'destinationAccount' => providerData_['destinationAccount'],
		              'transferType'       => providerData_['transferType'],
		              'currencyCode'       => currencyCode_,
		              'amount'             =>amount_,
		              'metadata'           =>metadata_
		}

		url      = getMobilePaymentB2BUrl()
		response = self.sendJSONRequest(url, parameters)

		if (@response_code == HTTP_CREATED)
			resultObj = JSON.parse(response, :quirky_mode =>true)
			return resultObj
		end
		raise AfricasTalkingGatewayException(response)
	end

	def getUserData()
		url      = getUserDataUrl() + "?username=#{@user_name}"
		response = executePost(url)
		if (@response_code == HTTP_OK)
			result = JSON.parse(response, :quirky_mode =>true)['UserData']
			return result
		else
			raise AfricasTalkingGatewayException, response
		end
	end

	def executePost(url_, data_ = nil)
		uri		 	     = URI.parse(url_)
		http		     = Net::HTTP.new(uri.host, uri.port)
		http.use_ssl     = true
		headers = {
		   "apikey" => @api_key,
		   "Accept" => "application/json"
		}
		if(data_ != nil)
			request = Net::HTTP::Post.new(uri.request_uri)
			request.set_form_data(data_)
		else
		    request = Net::HTTP::Get.new(uri.request_uri)
		end
		request["apikey"] = @api_key
		request["Accept"] = "application/json"

		response          = http.request(request)

		if (DEBUG)
			puts "Full response #{response.body}"
		end

		@response_code = response.code.to_i
		return response.body
	end

	def sendJSONRequest(url_, data_)
		uri	       = URI.parse(url_)
		http         = Net::HTTP.new(uri.host, uri.port)
		http.use_ssl = true
		req          = Net::HTTP::Post.new(uri.request_uri, 'Content-Type'=>"application/json")

		req["apikey"] = @api_key
		req["Accept"] = "application/json"

		req.body = data_.to_json

		response  = http.request(req)

		if (DEBUG)
			puts "Full response #{response.body}"
		end

		@response_code = response.code.to_i
		return response.body
	end

	def getApiHost()
		if(@environment == "sandbox")
			return "https://api.sandbox.africastalking.com"
		else
			return "https://api.africastalking.com"
		end
	end

	def getVoiceHost()
		if(@environment == "sandbox")
			return "https://voice.sandbox.africastalking.com"
		else
			return "https://voice.africastalking.com"
		end
	end

	def getPaymentHost()
		if(@environment == "sandbox")
			return "https://payments.sandbox.africastalking.com"
		else
			return "https://payments.africastalking.com"
		end
	end

	def getSmsUrl()
		return  getApiHost() + "/version1/messaging"
	end

	def getVoiceUrl()
        return getVoiceHost()
	end

	def getSmsSubscriptionUrl()
		return getApiHost() + "/version1/subscription"
	end

	def getUserDataUrl()
		return getApiHost() + "/version1/user"
	end

	def getAirtimeUrl()
		return getApiHost() + "/version1/airtime"
	end

	def getMobilePaymentCheckoutUrl()
		return getPaymentHost() + "/mobile/checkout/request"
	end

	def getMobilePaymentB2CUrl()
		return getPaymentHost() + "/mobile/b2c/request"
	end

	def getMobilePaymentB2BUrl()
		return getPaymentHost() + "/mobile/b2b/request"
	end
end
