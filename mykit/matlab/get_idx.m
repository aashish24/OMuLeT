function idx = get_idx(idx_begin, idx_end, num)
%GET_IDX Summary of this function goes here
%   Detailed explanation goes here
    if idx_end-idx_begin<0
        idx=[];
    elseif idx_end-idx_begin<=1
        idx=ones(1,num);
    else
        idx=floor(idx_begin:(idx_end-idx_begin)/(num-1):idx_end);
    end
end

