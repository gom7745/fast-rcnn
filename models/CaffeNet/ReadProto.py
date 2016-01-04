import caffe
from caffe.proto import caffe_pb2
from google.protobuf import text_format

class ReadProto:
    def __init__(self, filepath):
        self.parser_object = self._readProtoSolverFile(filepath)
    def _readProtoSolverFile(self, filepath):
        solver_config = caffe.proto.caffe_pb2.NetParameter()
        #TODO how to read proto file?
        return self._readProtoFile(filepath, solver_config)
    #enddef

    def _readProtoFile(self, filepath, parser_object):
        file = open(filepath, "r")
        if not file:
            raise self.ProcessException("ERROR (" + filepath + ")!")
        text_format.Merge(str(file.read()), parser_object)
        file.close()
        return parser_object
    #enddef
