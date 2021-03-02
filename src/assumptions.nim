
# proc parseAssumptionsBlock(parser: var NexusParser) = 
#   while true:
#     parser.nextToken()
#     case parser.token.toLower()
#     of "charpartition":
#         while true:
#           parser.nextToken()
#           case parser.token.toLower()
#           of
#     of "charset":
#     of "codeset":
#     of "codonposset":
#     of "options":
#     of "taxset":
#     of "taxpartition":
#     of "treeset":
#     of "treepartition":
#     of "typeset":
#     of "usertype":
#     of "wtset":
#     of "end":
#       parser.checkSemicolon()
#       parser.state = nxStateEndBlock
#       break     
#     else:
#       parser.raiseException(InvalidNexusCommand, "Unrecognized command", printToken=true)


# proc parseAssumptionsBlock(parser:var NexusParser) = 
#   while true:
#     parser.nextToken()
#     case parser.token.toLower()
#     of "options":
#       while true:
#         parser.nextToken()
#         case parser.token.toLower()
#         of "deftype":
#           var deftype = parser.parseArg()
#         of "polytcount":
#           var polytcount = parser.parseArg().toLower()
#           if polytcount == "ministeps":
#             var ministeps = true
#           elif polycount == "maxsteps":
#             var maxsteps = true
#           else:
#             quit("Invalid value for \"polycount\"")
#         else:
#           quit("Invalid options ")
#     # of "usertype":
#     # of "typeset":
#     # of "wtset":
#     # of "exset":
#     # of "ancstates":
#     of "end":
#       parser.state = nxStateEndBlock
#       parser.checkSemicolon()
#       break
#     else:


