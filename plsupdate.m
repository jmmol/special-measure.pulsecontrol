function plsupdate(newdef)
% plsupdate(newdef)
% Update group parameters. (offset, matrix, params, varpar, trafofn; jump, nrep) 
% All other fields of the group definition struct are ignored.
% Their dimensions are not allowed to change to keep the group size the
% same. The current time is stored in lastupdate. Changing jump and nrep only
% (no other fields set) does not require reloading pulses.

% l.76: Also change time if exists in newdef (Pascal 2014_04_03)

% (c) 2010 Hendrik Bluhm.  Please see LICENSE and COPYRIGHT information in plssetup.m.

% Not implmented: Missing or nan entries of params are taken from previous values.

global plsdata;
global vawg;

if length(newdef) > 1
    if iscell(newdef)
        for l=1:length(newdef)
            plsupdate(newdef{l});
        end
    else        
        for l=1:length(newdef)
            plsupdate(newdef(l));
        end
    end
    return;
end

file = [plsdata.grpdir, 'pg_', newdef.name];
load(file);

plschng = false;

if isfield(newdef, 'offset')
    if length(newdef.offset) ~= length(grpdef.offset)
        error('Size of offset changed.');
    end
    grpdef.offset = newdef.offset;
    plschng = 1;
end

if isfield(newdef, 'matrix')
    if any(size(newdef.matrix) ~= size(grpdef.matrix))
        error('Size of matrix changed.');
    end
    grpdef.matrix = newdef.matrix;
    plschng = 1;
end

if isfield(newdef, 'dict')    
    grpdef.dict=newdef.dict;
    plschng=1;
end

if isfield(newdef, 'params')
    if length(newdef.params) ~= length(grpdef.params)
        error('Size of params changed.');
    end
    grpdef.params = newdef.params;
    plschng = 1;
end

if isfield(newdef, 'varpar')
    if any(size(newdef.varpar, 1) ~= size(grpdef.varpar, 1))
        error('Size of varpar changed.');
    end
    grpdef.varpar = newdef.varpar;
    plschng = 1;
end

if isfield(newdef, 'xval')
    grpdef.xval = newdef.xval;
    plschng = 1;
end

if isfield(newdef, 'time')
    grpdef.time = newdef.time;
    plschng = 1;
end

if isfield(newdef,'ctrl')
    grpdef.ctrl = newdef.ctrl;
    if isempty(grpdef.ctrl) || isempty(strmatch(grpdef.ctrl(1:min([end find(grpdef.ctrl == ' ', 1)-1])), {'pls', 'grp', 'grpcat'}))
    % format not given
    if ~isstruct(grpdef.pulses) || isfield(grpdef.pulses, 'data')
        grpdef.ctrl = ['pls ' grpdef.ctrl];
    elseif isfield(grpdef.pulses, 'groups')
        grpdef.ctrl = ['grp ' grpdef.ctrl];   
    else
        error('Invalid group format.');
    end
    end
    plschng = 1;
end

if isfield(newdef, 'trafofn')
    if isempty(newdef.trafofn) && isfield(newdef, 'trafofn')
        grpdef = rmfield(grpdef, 'trafofn');
    end
    grpdef.trafofn = newdef.trafofn;
    plschng = 1;
end

% some may not be valid for 'grp' groups
% allow channel changes?

% didn't want to log this, but should be able to log add it any time (only
% logged if given)
% if isfield(newdef, 'pulseind')
%     if any(size(newdef.pulseind) ~= size(grpdef.pulseind))
%         error('Size of pulseind changed.');
%     end
%     grpdef.pulseind = newdef.pulseind;
% end

%if isfield(newdef, 'pulseind') % currently not updateable
%    grpdef.pulseind = newdef.pulseind;
%end

if isfield(newdef, 'nrep')
    plschng = 1;
    grpdef.nrep = newdef.nrep;
end

if isfield(newdef, 'jump')
    plschng = 1;
    grpdef.jump = newdef.jump;
end

% may be buggy below.
if isfield(newdef,'pulses')
    if isnumeric(newdef.pulses) && any(newdef.pulses ~= grpdef.pulses)
        error('plsupdate cannot change pulse numbers');
    elseif isfield(newdef.pulses,'groups')
        for i=1:length(newdef.pulses.groups)
            if ~strcmp(newdef.pulses.groups{i},grpdef.pulses.groups{i})
                error('plsupdate cannot change inner pulse groups');
            end
        end
    end
end
    

if plschng % pulses changed
    lastupdate = now;
    save(file, '-append', 'grpdef', 'lastupdate');
    logentry('Updated group %s.', grpdef.name);
    
    for awg = vawg.awgs
        awg.markforupdate(grpdef.name);
    end

else
    fprintf('Didn''t update group "%s": nothing changed\n',grpdef.name);
end

fprintf('Updated group %s.\n', grpdef.name);
