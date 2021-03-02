

# proc parseTreesBlock(parser: var NexusParser) = 
#   while true:
#     parser.nextToken()
#     case parser.token.toLower()
#     of "translate":
#       while true:
#         parser.nextToken()
#         case parser.token.toLower()
#         of ";":
#           break
#         else:
#           var translate = parser.token
#     of "tree":
#       while true:
#         parser.nextToken()
#         case parser.token.toLower()
#         of ";":
#           break
#         else:
#           var tree = parser.token
#     of "utree":
#       while true:
#         parser.nextToken()
#         case parser.token.toLower()
#         of ";":
#           break
#         else:
#           var tree = parser.token
#     of "end":
#       parser.checkSemicolon()
#       parser.state = nxStateEndBlock
#       break
#     else:
#       parser.raiseException(InvalidNexusCommand, "Invalid Tree block command", printToken=true)
