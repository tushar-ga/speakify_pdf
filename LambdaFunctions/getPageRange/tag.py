class Tag(object):
    def __init__(self, text, fontSize, start_page, start_block, end_page, end_block):
        self.text = text
        self.fontSize = fontSize
        self.start_page = start_page
        self.start_block = start_block
        self.child = []
        self.end_page = end_page
        self.end_block = end_block
    
    def __repr__(self):
        return "\"%s\" , FS: %s , Loc: P%s|B%s to P%s|B%s"%(self.text,self.fontSize,
                                                            self.start_page,self.start_block,
                                                            self.end_page,self.end_block)