# -*- ruby -*-
#--
# Copyright 2008 Danny Coates, Ashkan Farhadtouski
# All rights reserved.
# See LICENSE for permissions.
#++

require 'logger'

module HealthVault
  APPLICATIONID = "05a059c9-c309-46af-9b86-b06d42510550"
  CERTFILE = "certs/HelloWorld-SDK_ID-05a059c9-c309-46af-9b86-b06d42510550.pfx"
  SHELL_URL = "https://account.healthvault-ppe.com"
  HEALTHVAULT_URL = "https://platform.healthvault-ppe.com/platform/wildcat.ashx"
  LOGGER = Logger.new("hv.log")
  LOGGER.level = Logger::ERROR
end