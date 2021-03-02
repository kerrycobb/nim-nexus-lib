

# proc parseTaxaBlock(parser: var NexusParser) = 
#   while true:
#     parser.nextToken()
#     case parser.token.toLower()
#     of "dimensions":
#       while true:
#         parser.nextToken()
#         case parser.token
#         of "ntax":
#           var ntax = parser.parseArg()
#         of ";": 
#           break
#         else:
#           quit("Invalid taxa block token")
#     of "taxlabels":
#       while true:
#         parser.nextToken()
#         if parser.token == ";":
#           break
#         else:
#           var taxLabel =  parser.token
#     of "end":
#       parser.checkSemicolon()
#       parser.state = nxStateEndBlock
#       break
#     else:
#       parser.raiseException(InvalidNexusCommand, fmt"Invalid Taxa block command {parser.token}", printToken=true)
