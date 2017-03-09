classdef downsampleTests < matlab.unittest.TestCase

	properties
		exampleCells = '../exampleData/selected_cells.yml';
		exampleTree  = '../exampleData/traced_cell.mat';
		newDStxtFile  = '../exampleData/dsNEW_25_25_02.txt';		
		oldDStxtFile  = '../exampleData/dsOLD_25_25_02.txt';		
	end %properties

	%Open test method block
	methods (Test)

		function testExportMissingDataFile(testCase)
			%Does exportSparseMaSIVData correctly bail out if the data file is not present?
			out = exportSparseMaSIVData(fullfile(tempdir,'doesNotExist.mat'),[],0);
 			testCase.verifyTrue(out == -1);
		end

		function testExportMissingDownSampleFile(testCase)
			%Does exportSparseMaSIVData correctly bail out if the downsample text file is missing?
			out = exportSparseMaSIVData(testCase.exampleCells,fullfile(tempdir,'doesNotExist.mat'),0);
 			testCase.verifyTrue(out == -2);
		end

		function testExportOldTextFile(testCase)
			%Does exportSparseMaSIVData correctly bail out if it is fed an old format downsample text file?
			out = exportSparseMaSIVData(testCase.exampleCells,testCase.oldDStxtFile,0);
 			testCase.verifyTrue(out == -3);
		end

		function testExportExampleTree(testCase)
			%Does exportSparseMaSIVData correctly export a neurite tree file
			out = exportSparseMaSIVData(testCase.exampleTree,testCase.newDStxtFile,0);
 			testCase.verifyTrue(isstruct(out) & length(out)==1); %Do we get the expected output?
 			testCase.verifyTrue(exist('./traced_cell_tree_01.csv','file')==2); %Is the file there?
 			delete('./traced_cell_tree_01.csv')
		end

		function testExportExamplePoints(testCase)
			%Does exportSparseMaSIVData correctly export selected cells (points)
			out = exportSparseMaSIVData(testCase.exampleCells,testCase.newDStxtFile,0);
 			testCase.verifyTrue(isstruct(out) & length(out)==1); %Do we get the expected output?
 			testCase.verifyTrue(exist('./selected_cells_02.csv','file')==2); %Is the file there?
 			delete('./selected_cells_02.csv')
		end


	end %methods (Test)

end %classdef settings_handler_Test < matlab.unittest.TestCase