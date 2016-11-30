class Nexmo
  SEND_STATUS = {
    "0" => [
      "Success",
      "The message was successfully accepted for delivery by Nexmo."
    ],
    "1" => [
      "Throttled",
      "You have exceeded the submission capacity allowed on this account. Please wait and retry."
    ],
    "2" => [
      "Missing params",
      "Your request is incomplete and missing some mandatory parameters."
    ],
    "3" => [
      "Invalid params",
      "The value of one or more parameters is invalid."
    ],
    "4" => [
      "Invalid credentials",
      "The api_key / api_secret you supplied is either invalid or disabled."
    ],
    "5" => [
      "Internal error",
      "There was an error processing your request in the Platform."
    ],
    "6" => [
      "Invalid message",
      "The Platform was unable to process your request. For example, due to an unrecognized prefix for the phone number."
    ],
    "7" => [
      "Number barred",
      "The number you are trying to submit to is blacklisted and may not receive messages."
    ],
    "8" => [
      "Partner account barred",
      "The api_key you supplied is for an account that has been barred from submitting messages."
    ],
    "9" => [
      "Partner quota exceeded",
      "Your pre-paid account does not have sufficient credit to process this message."
    ],
    "11" => [
      "Account not enabled for REST",
      "This account is not provisioned for REST submission, you should use SMPP instead."
    ],
    "12" => [
      "Message too long",
      "The length of udh and body was greater than 140 octets for a binary type SMS request."
    ],
    "13" => [
      "Communication Failed",
      "Message was not submitted because there was a communication failure."
    ],
    "14" => [
      "Invalid Signature",
      "Message was not submitted due to a verification failure in the submitted signature."
    ],
    "15" => [
      "Invalid sender address",
      "Due to local regulations, the SenderID you set in from in the request was not accepted. Please check the Global messaging section."
    ],
    "16" => [
      "Invalid TTL",
      "The value of ttl in your request was invalid."
    ],
    "19" => [
      "Facility not allowed",
      "Your request makes use of a facility that is not enabled on your account."
    ],
    "20" => [
      "Invalid Message class",
      "The value of message-class in your request was out of range."
    ],
    "23" => [
      "Bad callback :: Missing Protocol",
      "You did not include https in the URL you set in callback."
    ],
    "29" => [
      "Non White-listed Destination",
      "The phone number you set in to is not in your pre-approved destination list. To send messages to this phone number, add it using Dashboard."
    ],
    "34" => [
      "Invalid or Missing Msisdn Param",
      "The phone number you supplied in the to parameter of your request was either missing or invalid."
    ],
    "101" => [
      "RESPONSE_INVALID_ACCOUNT_CAMPAIGN",
      "You tried to send a message to a destination number that has opted out of your program."
    ],
    "102" => [
      "RESPONSE_INVALID_CAMPAIGN_SHORTCODE",
      ""
    ],
    "103" => [
      "RESPONSE_INVALID_MSISDN",
      ""
    ]
  }

  DELIVERY_STATUS = {
    "0" => [
      "Delivered",
      ""
    ],
    "1" => [
      "Unknown",
      "An unknown error was received from the carrier who tried to send this this message."
    ],
    "2" => [
      "Absent Subscriber Temporary",
      "This message was not delivered because to was temporarily unavailable. For example, the handset used for to was out of coverage or switched off. This is a temporary failure, retry later for a positive result."
    ],
    "3" => [
      "Absent Subscriber Permanent",
      "To is no longer active, you should remove this phone number from your database."
    ],
    "4" => [
      "Call barred by user",
      "You should remove this phone number from your database. If the user wants to receive messages from you, they need to contact their carrier directly."
    ],
    "5" => [
      "Portability Error",
      "There is an issue after the user has changed carrier for to. If the user wants to receive messages from you, they need to contact their carrier directly."
    ],
    "6" => [
      "Anti-Spam Rejection",
      "Carriers often apply restrictions that block messages following different criteria. For example, on SenderID or message content."
    ],
    "7" => [
      "Handset Busy",
      "The handset associated with to was not available when this message was sent. If status is Failed, this is a temporary failure; retry later for a positive result. If status is Accepted, this message has is in the retry scheme and will be resent until it expires in 24-48 hours."
    ],
    "8" => [
      "Network Error",
      "A network failure while sending your message. This is a temporary failure, retry later for a positive result."
    ],
    "9" => [
      "Illegal Number",
      "You tried to send a message to a blacklisted phone number. That is, the user has already sent a STOP opt-out message and no longer wishes to receive messages from you."
    ],
    "10" => [
      "Invalid Message",
      "The message could not be sent because one of the parameters in the message was incorrect. For example, incorrect type or udh."
    ],
    "11" => [
      "Unroutable",
      "The chosen route to send your message is not available."
    ],
    "12" => [
      "Destination unreachable",
      "The message could not be delivered to the phone number."
    ],
    "13" => [
      "Subscriber Age Restriction",
      "The carrier blocked this message because the content is not suitable for to based on age restrictions."
    ],
    "14" => [
      "Number Blocked by Carrier",
      "The carrier blocked this message. This could be due to several reasons. For example, to's plan does not include SMS or the account is suspended."
    ],
    "15" => [
      "Pre-Paid - Insufficent funds",
      "To's pre-paid account does not have enough credit to receive the message."
    ],
    "99" => [
      "General Error",
      "There is a problem with the chosen route to send your message. To resolve this issue either email us at support@nexmo.com or create a helpdesk ticket at https://help.nexmo.com."
    ]
  }
end