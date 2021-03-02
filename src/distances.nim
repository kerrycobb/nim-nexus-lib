
# proc parseDistancesBlock(parser: var NexusParser) = 
#   while true:
#     parser.nextToken()
#     case parser.token.toLower()
#     of "dimensions":
#       while true:
#         parser.nextToken()
#         case parser.token.toLower()
#         of "ntax", "newtaxa":
#           var ntax =  parser.parseArg()
#         of "nchar":
#           var nchar = parser.parseArg()
#         of ";":
#           break
#         else:
#           quit("Invalid dimensions argument")
#     of "format":
#       while true:
#         parser.nextToken()
#         case parser.token.toLower()
#         of "triangle":
#           var 
#             triangle = parser.parseArg().toLower()
#             tri = ""
#           case triangle 
#           of "lower":
#             tri = "lower"
#           of "upper":
#             tri = "upper"
#           of "both":
#             tri = "both"
#           else:
#             quit("Invalid triangle value")
#         of "diagonal":
#           var diagonal = true
#         of "nodiagonal":
#           var nodiagonal = true
#         of "labels":
#           var labels = true
#         of "nolabels":
#           var nolabels = true
#         of "missing":
#           var missing = parser.parseArg()
#         of "interleave":
#           var interleave = true
#         of ";":
#           break
#         else:
#           quit("Invalid distance format argument")
#     of "taxlabels":
#       while true:
#         parser.nextToken()
#         if parser.token == ";":
#           break
#         else:
#           quit("Expected ;")
#     of "matrix": 
#       while true:
#         parser.nextToken()
#         if parser.token == ";":
#           break
#         else:
#           var matrix = parser.token
#     of "end":
#       parser.checkSemicolon()
#       parser.state = nxStateEndBlock
#       break
#     else:
#       parser.raiseException(InvalidNexusCommand, fmt"Invalid Distances block command {parser.token}", printToken=true)
