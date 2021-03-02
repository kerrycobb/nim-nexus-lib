{. warning[UnusedImport]:off .}

import streams, lexbase, strutils, phylogeni, nim_seq, strformat

const 
  NexusWhitespace = {' ', '\t', '\c', '\l'}
  Newlines = {'\l', '\c'}

  iupacDNAChars = {'A','G','C','T','R','M','W','S','K','Y','V','H', 
      'D','B','N'}
  iupacRNAChars = {'A','G','C','U','R','M','W','S','K','Y','V','H', 
      'D','B','N'}

type
  # NexusAssumptions = ref object
  #   charPartition: string
  #   charSet: string
  #   codeSet: string
  #   codonPosSet: string
  #   options: string
  #   taxSet: string
  #   taxPartition: string
  #   treeSet: string
  #   treePartition: string
  #   typeSet: string
  #   userType: string
  #   wtSet: string

  # NexusCharacters = ref object
  #   dimensions: string
  #   format: string
  #   taxLabels: string
  #   charStateLabels: string
  #   charLabels: string
  #   stateLabels: string
  #   matrix: string

  # NexusDistances = ref object
  #   dimensions: string
  #   format: string
  #   taxLabels: string
  #   matrix: string

  # NexusTaxa = ref object
  #   dimensions: string
  #   taxLabels: string

  # NexusTrees = ref object
  #   translate: string
  #   trees: string

  # NexusUnaligned = ref object
  #   dimensions: string
  #   format: string
  #   taxLabels: string
  #   matrix: string

  # Nexus = ref object
  #   assumptions: NexusAssumptions
  #   characters: NexusCharacters
  #   distances: NexusDistances
  #   taxa: NexusTaxa
  #   trees: NexusTrees
  #   unaligned: NexusUnaligned

  NexusError = object of IOError
  UnexpectedNexusEOF = object of EOFError
  InvalidNexus = object of NexusError
  InvalidNexusBlock = object of NexusError  
  InvalidNexusCommand = object of NexusError
  InvalidNexusArgument = object of NexusError
  InvalidNexusValue = object of NexusError

  NexusState = enum
    nxStateStart, nxStateEndBlock, nxStateEOF

  NexusParser = object of BaseLexer
    # nexus: Nexus
    token: string
    state: NexusState
  
  NexusMatrixDatatype = enum
    nxmdStandard, nxmdDna, nxmdRna, nxmdNucleotide, nxmdProtein, nxmdContinuous

proc raiseException(parser: NexusParser, errorType: typedesc, msg: string, printToken=false) =
  var 
    line = parser.lineNumber
    col = parser.getColNumber(parser.bufpos) - parser.token.len + 1
    e = new(errorType)
  e.msg.add(msg)
  if printToken:
    e.msg.add(&": \"{parser.token}\"")
  e.msg.add(fmt" at (Ln{line},Col{col})")
  raise e 

proc parseWhitespace(parser: var NexusParser, skip=true) = 
  case parser.buf[parser.bufpos]
  of '\c':
    parser.bufpos = lexbase.handleCR(parser, parser.bufpos)
    if not skip:
      parser.token.add('\n')
  of '\l': # same as \n
    parser.bufpos = lexbase.handleLF(parser, parser.bufpos)
    if not skip:
      parser.token.add('\n')
  of ' ', '\t':
    parser.bufpos.inc()
    if not skip:
      parser.token.add(' ')
  else:
    parser.raiseException(InvalidNexus, "Expected whitespace")

proc nextToken(parser: var NexusParser, skip=true) = 
  parser.token.setLen(0)
  while true:
    case parser.buf[parser.bufpos]
    of EndOfFile:
      if parser.state == nxStateEndBlock:
        parser.state = nxStateEof
        break
      else:
        parser.raiseException(UnexpectedNexusEOF, "Unexpected end of nexus stream")
    of NexusWhitespace:
      parser.parseWhitespace(skip=skip)
      if not skip:
        break
    of ';':
        parser.bufPos.inc()
        parser.token = ";"
        break
    of '=':
      parser.bufPos.inc()
      parser.token = "=" 
      break
    of '[': # Skip over comment
      var lvl = 0
      while true:
        case parser.buf[parser.bufpos]
        of NexusWhitespace:
          parser.parseWhitespace()
        of '[':
          parser.bufpos.inc()
          lvl.inc()
        of ']':
          parser.bufpos.inc()
          lvl.inc(-1)
          if lvl == 0: 
            break
        else:
          parser.bufpos.inc()
    of '"':
      parser.token.add('"')
      parser.bufpos.inc()
      while true:
        case parser.buf[parser.bufpos]
        of '"':
          parser.token.add('"')
          parser.bufpos.inc()
          break
        of NexusWhitespace:
          parser.parseWhitespace(skip=false)
        else:
          parser.token.add(parser.buf[parser.bufpos])
          parser.bufpos.inc()
      break
    of '(':
      while true:
        case parser.buf[parser.bufpos]
        of ')':
          parser.bufpos.inc()
          break
        of NexusWhitespace:
          if parser.token == " ":
            parser.token.add(parser.buf[parser.bufpos])
          parser.parseWhitespace()
        else:
          parser.token.add(parser.buf[parser.bufpos])
          parser.bufpos.inc()
    else:
      while true: 
        case parser.buf[parser.bufpos]
        of NexusWhitespace, ';', '[', '=':
          break
        else:
          parser.token.add(parser.buf[parser.bufpos])
          parser.bufpos.inc()
      break

proc checkSemicolon*(parser: var NexusParser) = 
  parser.nextToken()
  if parser.token != ";":
    parser.raiseException(InvalidNexus, "Expected ';'")

proc parseArg*(parser: var NexusParser): string = 
  parser.nextToken()
  if parser.token == "=":
    var next = parser.buf[parser.bufpos]
    if next == ' ' or next == ';':
      parser.raiseException(InvalidNexus, "Expected value after \"=\"")
    else:
      parser.nextToken()
      result = parser.token 
  else:
    parser.raiseException(InvalidNexus, "Expected \"=\"")

proc expectLineBreak*(parser: var NexusParser) =
  while true: 
     if parser.buf[parser.bufpos] in Whitespace:
       if parser.buf[parser.bufpos] in Newlines:
         parser.parseWhitespace(skip=false) 
         break
       else:
        parser.parseWhitespace(skip=false) 
     else:
       parser.raiseException(InvalidNexus, "Expected whitespace or newline character")

proc parseCharactersBlock*(parser: var NexusParser) = 
  var
    interleaved = false
    gap = "-"
    missing = "?"
    datatype: NexusMatrixDatatype 
    symbols: string 
    alignment = Alignment()

  while true:
    parser.nextToken()
    case parser.token.toLower()
    of "dimensions":
      while true:
        parser.nextToken()
        case parser.token.toLower()
        of "ntax":
          alignment.ntax = parseInt(parser.parseArg())
        of "nchar":
          alignment.nchar = parseInt(parser.parseArg())
        of ";":
          break
        else:
          parser.raiseException(InvalidNexusArgument,
              "Invalid Dimensions command argument", printToken=true) 
    of "format":
      while true:
        parser.nextToken()
        case parser.token.toLower()
        of "datatype":
          var 
            dt = parser.parseArg().toLower()
          case dt
          of "standard":
            dataType = nxmdStandard 
          of "dna":
            dataType = nxmdDna 
          of "rna":
            dataType = nxmdRna 
          of "nucleotide":
            dataType = nxmdNucleotide 
          of "protein":
            dataType = nxmdProtein 
          of "continuous":
            dataType = nxmdContinuous 
          else:
            parser.raiseException(InvalidNexusValue, 
                "Invalid value for DataType command", printToken=true)
        #   echo fmt"DataType: {dt}"
        # of "respectcase":
        #   var respectCase = true 
        of "missing":
          missing = parser.parseArg()
        of "gap":
          gap = parser.parseArg()
        of "symbols":
          symbols = parser.parseArg()
        # of "equate":
        #   var equate = parser.parseArg()
        # of "matchchar":
        #   var matchChar = parser.parseArg()
        # of "labels":
        #   var labels = true 
        # of "nolabels":
        #   var noLabels = false 
        # of "transpose":
        #   var transpose = true
        of "interleave":
          interleaved = true
        # of "items":
        #   var items = parser.parseArg()
        # of "statesformat":
        #   var statesFormat = "" 
        #   while true:
        #     parser.nextToken()
        #     case parser.token.toLower()
        #     of "statespresent":
        #       statesFormat = "statespresent"
        #     of "individuals":
        #       statesFormat = "individuals"
        #     of "count":
        #       statesFormat = "count"
        #     of "frequency":
        #       statesFormat = "frequency"
        #     else:
        #       quit("Invalid statesformat")
        # of "tokens":
        #   var tokens = true 
        # of "notokens":
        #   var notokens = true
        of ";":
          break
        else:
          parser.raiseException(InvalidNexusArgument,
              "Invalid Format command argument", printToken=true) 
    # of "eliminate":
    # of "taxlabels":
    # of "charstatelabels":
    #   var charStateLabels: string
    #   while true:
    #     parser.nextToken()
    #     case parser.token
    #     of ";":
    #       break
    #     else:
    #       charStateLabels = parser.token
    # of "charlabels":
    # of "statelabels": 
    of "matrix":
      var 
        firstPass = true
        taxonIx = 0
      parser.expectLineBreak()
      block matrixBlock:
        while true: # While still in matrix block
          parser.nextToken()
          var id = parser.token
          while true: # read to end of line 
            case parser.buf[parser.bufpos]
            of Whitespace:
              if parser.buf[parser.bufpos] in Newlines:
                parser.parseWhitespace(skip=false)
                taxonIx.inc()               
                break
              else:
                parser.parseWhitespace(skip=false)
            of ';':
              parser.nextToken()
              break matrixBlock
            else:
              # alignment.seqs[taxonIx].data.add(toNucleotide(parser.buf[parser.bufpos]))
              parser.bufpos.inc()
          while true: # determine if end of matrix or interleave section 
            case parser.buf[parser.bufpos]
            of Whitespace:
              if parser.buf[parser.bufpos] in Newlines:
                if firstPass:
                  echo taxonIx 
                  if alignment.ntax == 0:
                    alignment.ntax = taxonIx 
                  else:
                    parser.raiseException(InvalidNexus, 
                        "Number of taxa in matrix block does not match ntax argument")
                else:
                  if alignment.ntax != taxonIx: 
                    parser.raiseException(InvalidNexus, "Wrong number of rows")
                taxonIx = 0
                parser.parseWhitespace(skip=false)
                break
              else:
                parser.parseWhitespace(skip=false)
            of ';':
              parser.nextToken()
              break matrixBlock
            else:
              break
    of "end":
      parser.state = nxStateEndBlock
      parser.checkSemicolon()
      echo alignment[]
      break
    else:
      parser.raiseException(InvalidNexusCommand, 
          "Invalid Characters block command", printToken=true)

proc parseNexusStream*(stream: Stream) = #: Nexus = 
  var 
    parser: NexusParser 
  # parser.nexus = Nexus()
  parser.open(stream)
  parser.nextToken()
  if parser.token.toLower() != "#nexus": 
    parser.raiseException(InvalidNexus, "Expected \"#nexus\"")
  while true:
    parser.nextToken()
    case parser.state
    of nxStateStart, nxStateEndBlock:
      if parser.token.toLower() == "begin":
        parser.nextToken()
        case parser.token.toLower()
        # of "assumptions", "codons", "sets":
        #   parser.checkSemicolon()
        #   parser.parseAssumptionsBlock()
        of "characters", "data":
          parser.checkSemicolon()
          parser.parseCharactersBlock()
        # of "distances":
        #   parser.checkSemicolon()
        #   parser.parseDistancesBlock()
        # of "taxa":
        #   parser.checkSemicolon()
        #   parser.parseTaxaBlock() 
        # of "trees":
        #   parser.checkSemicolon()
        #   parser.parseTreesBlock()
        # of "unaligned": 
        else:
          echo &"Unknown block \"{parser.token}\""
          while true:
            parser.nextToken()
            if parser.token == "end": 
              parser.checkSemicolon()
              break
          # parser.raiseException(InvalidNexusBlock, "Invalid block name", printToken=true)
      else:
        echo parser.token
        parser.raiseException(InvalidNexus, "Expected \"begin\"")
    of nxStateEOF:
      break
  # result = parser.nexus

proc parseNexusString*(str: string) = #: Nexus =
  ## Parse a nexus string
  var ss = newStringStream(str)
  # result = 
  parseNexusStream(ss)
  ss.close()

proc parseNexusFile*(path: string) = #: Nexus =
  ## Parse a nexus file
  var fs = newFileStream(path, fmRead)
  # result = 
  parseNexusStream(fs)
  fs.close()

# var nx = 
parseNexusFile("test2.nex")

# try:
#   parseNexusFile("test.nex")
# except UnexpectedNexusEOF:
#   echo "error"
# except:
#   discard
# except InvalidNexus:
#   discard
# except InvalidNexusBlock:
#   discard
# except InvalidNexusCommand:
#   discard
# except InvalidNexusArgument:
#   discard

